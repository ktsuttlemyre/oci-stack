variable "total_storage" {
  type    = number
  default = 200
}

variable "minimum_bootvolume_size" {
  type    = number
  default = 50
}

data "oci_identity_tenancy" "tenancy" {
    #Required
    tenancy_id = var.tenancy_ocid
}
resource "random_id" "id" {
	  byte_length = 8
}

resource "oci_identity_compartment" "this" {
  compartment_id = var.tenancy_ocid
  description    = replace("${var.name}-compartment", " ", "-")
  name           = replace("${var.name}-compartment-${random_id.id.hex}", " ", "-")

  enable_delete = true
}


# a better network example can be found here
# https://github.com/chadgeary/cloudblock/blob/49ae482df88bc08303b5bfddddf6d576906320a9/oci/oci-network.tf
resource "oci_core_vcn" "this" {
  compartment_id = oci_identity_compartment.this.id

  cidr_blocks  = [var.cidr_block]
  display_name = replace("${var.name}-vcn", " ", "-")
  dns_label    = "vcn"
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = oci_identity_compartment.this.id
  vcn_id         = oci_core_vcn.this.id

  display_name = oci_core_vcn.this.display_name
}

resource "oci_core_default_route_table" "this" {
  manage_default_resource_id = oci_core_vcn.this.default_route_table_id

  display_name = oci_core_vcn.this.display_name

  route_rules {
    network_entity_id = oci_core_internet_gateway.this.id

    description = "Default route"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_default_security_list" "this" {
  manage_default_resource_id = oci_core_vcn.this.default_security_list_id

  dynamic "ingress_security_rules" {
    for_each = [80, 443]
    iterator = port
    content {
      protocol = "all" #local.protocol_number.tcp
      source   = "0.0.0.0/0"

      description = "SSH and HTTPS traffic from any origin"
    }
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"

    description = "All traffic to any destination"
  }
}

resource "oci_core_subnet" "this" {
  cidr_block     = oci_core_vcn.this.cidr_blocks.0
  compartment_id = oci_identity_compartment.this.id
  vcn_id         = oci_core_vcn.this.id

  display_name = oci_core_vcn.this.display_name
  dns_label    = "subnet"
}

resource "oci_core_network_security_group" "this" {
  compartment_id = oci_identity_compartment.this.id
  vcn_id         = oci_core_vcn.this.id

  display_name = oci_core_vcn.this.display_name
}

resource "oci_core_network_security_group_security_rule" "this" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.this.id
  protocol                  = local.protocol_number.icmp
  source                    = "0.0.0.0/0"
}

#use the vault at the root with the same name as the tenancy
data "oci_kms_vaults" "this" {
     compartment_id = var.tenancy_ocid
}
data "oci_kms_vault" "this" {
     vault_id = "${data.oci_kms_vaults.this.vaults[index(data.oci_kms_vaults.this.vaults.*.display_name, data.oci_identity_tenancy.tenancy.name)].id}"
}

data "oci_kms_keys" "this" {
    #Required
    compartment_id = var.tenancy_ocid
    management_endpoint = data.oci_kms_vault.this.management_endpoint
}

data "oci_vault_secrets" "this" {
    #Required
    compartment_id = var.tenancy_ocid
    name = "OCI_CONFIG"
    vault_id = data.oci_kms_vault.this.id
}

data "oci_secrets_secretbundle" "this" {
      secret_id = data.oci_vault_secrets.this.secrets[0].id
}

resource "oci_vault_secret" "ampere_ip" {
    #Required
    compartment_id = var.tenancy_ocid
    secret_content {
        #Required
        content_type = "BASE64"

        #Optional
        content = "${base64encode(data.oci_core_private_ips.ampere.private_ips.0.ip_address)}"
    }
    secret_name = "AMPERE_PRIVATE_IP"
    vault_id = data.oci_kms_vault.this.id
    key_id = data.oci_kms_keys.this.keys[index(data.oci_kms_keys.this.keys.*.state, "ENABLED")].id
}

resource "oci_vault_secret" "micro_ip" {
    #Required
    compartment_id = var.tenancy_ocid
    secret_content {
        #Required
        content_type = "BASE64"

        #Optional
        content = "${base64encode(data.oci_core_private_ips.micro.private_ips.0.ip_address)}"
    }
    secret_name = "MICRO1_PRIVATE_IP"
    vault_id = data.oci_kms_vault.this.id
    key_id = data.oci_kms_keys.this.keys[index(data.oci_kms_keys.this.keys.*.state, "ENABLED")].id
}

data "oci_identity_availability_domains" "this" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_shapes" "this" {
  for_each = toset(data.oci_identity_availability_domains.this.availability_domains[*].name)

  compartment_id = var.tenancy_ocid

  availability_domain = each.key
}

data "oci_core_images" "this" {
  compartment_id = oci_identity_compartment.this.id

  operating_system         = "Canonical Ubuntu"
  shape                    = local.shapes.micro
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
  state                    = "available"

  filter {
    name   = "display_name"
    values = ["^Canonical-Ubuntu-([\\.0-9-]+)$"]
    regex  = true
  }
}

data template_file "user_data" {
  template = file("${path.module}/templates/user_data.yaml")

  vars = {
#    username           = var.username
#    ssh_public_key     = file(var.ssh_public_key)
#    packages           = jsonencode(var.packages)
    vault              = data.oci_kms_vaults.this.vaults[index(data.oci_kms_vaults.this.vaults.*.display_name, data.oci_identity_tenancy.tenancy.name)].id
    oci_config         = data.oci_secrets_secretbundle.this.secret_bundle_content[0].content
    init_script        = join("\n",[for fn in fileset(".", "./tenancy/${data.oci_identity_tenancy.tenancy.name}/**micro-1**") : file(fn)])
  }
}


resource "oci_core_instance" "micro" {
  count = var.number_of_micros

  availability_domain = local.availability_domain_micro
  compartment_id      = oci_identity_compartment.this.id
  shape               = local.shapes.micro

  display_name         = format("Micro %d", count.index + 1)
  preserve_boot_volume = false

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(<<EOF
#cloud-config
packages_update: true
packages_upgrade: true
#packages:
#  - git
#  - python3-pip
runcmd:
  # Note: Don't write files to /tmp from cloud-init use /run/somedir instead.
  # Early boot environments can race systemd-tmpfiles-clean LP: #1707222.
  - "set -ex"
  - "var(){ export $1=\"$2\" ; echo \"export $1='$2'\" | tee -a /home/ubuntu/.profile /root/.profile ; }"
  - "var VAULT ${data.oci_kms_vaults.this.vaults[index(data.oci_kms_vaults.this.vaults.*.display_name, data.oci_identity_tenancy.tenancy.name)].id}"
  - "var OCI_CONFIG ${data.oci_secrets_secretbundle.this.secret_bundle_content[0].content}"
  #- "var AMPERE_PRIVATE_IP {data.oci_core_private_ips.ampere.private_ips.0.ip_address}"
  - "var AMPERE_PUBLIC_IP \"\""
  # https://askubuntu.com/questions/1367139/apt-get-upgrade-auto-restart-services
  - "sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf"
  - "[ \"${var.skip_init_scripts}\" ] && exit 0 "
#  - "(( $EUID != 0 )) && echo \"Run this script as root\" && exit"
  - "bash /root/init_script.sh"
write_files:
  - encoding: b64
    content: ${base64encode(join("\n",concat(["#!/bin/bash -ex"],[for fn in fileset(".", "./tenancy/${data.oci_identity_tenancy.tenancy.name}/**micro-${count.index + 1}**") : file(fn)])))}
#    owner: "root:root"
    path: "/root/init_script.sh"
    permissions: '0755'
#{ for fn in fileset(".", "./tenancy/{data.oci_identity_tenancy.tenancy.name}/micro-{count.index + 1}/**") ~}
#  - encoding: b64
#{join("",["    ",join("\n    ",split("\n",split("-init-header-",file(fn))[0]))])}
#   content: {base64encode(reverse(split("-init-header-",file(fn)))[0])}
#{ endfor ~}
EOF
    )	  	  
  }

  agent_config {
    are_all_plugins_disabled = true
    is_management_disabled   = true
    is_monitoring_disabled   = true
  }

  availability_config {
    is_live_migration_preferred = null
  }

  create_vnic_details {
    assign_public_ip = false
    display_name     = format("Micro %d", count.index + 1)
    hostname_label   = format("micro-%d", count.index + 1)
    nsg_ids          = [oci_core_network_security_group.this.id]
    subnet_id        = oci_core_subnet.this.id
  }

  source_details {
    source_id               = data.oci_core_images.this.images.0.id
    source_type             = "image"
    boot_volume_size_in_gbs = 50
  }

  lifecycle {
    ignore_changes = [source_details.0.source_id]
  }
}

data "oci_core_images" "that" {
  compartment_id = oci_identity_compartment.this.id

  operating_system         = "Canonical Ubuntu"
  shape                    = local.shapes.flex
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
  state                    = "available"
}

resource "oci_core_instance" "ampere" {
  availability_domain = data.oci_identity_availability_domains.this.availability_domains.0.name
  compartment_id      = oci_identity_compartment.this.id
  shape               = local.shapes.flex

  display_name         = "Ampere"
  preserve_boot_volume = false

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(<<EOF
#cloud-config
packages_update: true
packages_upgrade: true
#packages:
#  - git
#  - python3-pip
runcmd:
  # Note: Don't write files to /tmp from cloud-init use /run/somedir instead.
  # Early boot environments can race systemd-tmpfiles-clean LP: #1707222.
  - "set -ex"
  - "var(){ export $1=\"$2\" ; echo \"export $1='$2'\" | tee -a /home/ubuntu/.profile /root/.profile ; }"
  - "var VAULT ${data.oci_kms_vaults.this.vaults[index(data.oci_kms_vaults.this.vaults.*.display_name, data.oci_identity_tenancy.tenancy.name)].id}"
  - "var OCI_CONFIG ${data.oci_secrets_secretbundle.this.secret_bundle_content[0].content}"
  - "var MICRO1_PRIVATE_IP ${data.oci_core_private_ips.micro.private_ips.0.ip_address}"
  - "var MICRO1_PUBLIC_IP \"\""
  # https://askubuntu.com/questions/1367139/apt-get-upgrade-auto-restart-services
  - "sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf"
  - "[ \"${var.skip_init_scripts}\" ] && exit 0 "
#  - "(( $EUID != 0 )) && echo \"Run this script as root\" && exit"
#  - "cd $HOME"
  - "bash /root/init_script.sh"
write_files:
  - encoding: "b64"
    content: ${base64encode(join("\n",concat(["#!/bin/bash -ex"],[for fn in fileset(".", "./tenancy/${data.oci_identity_tenancy.tenancy.name}/**ampere**") : file(fn)])))}
#    owner: "root:root"
    path: "/root/init_script.sh"
    permissions: '0755'
#{ for fn in fileset(".", "./tenancy/{data.oci_identity_tenancy.tenancy.name}/ampere/**") ~}
#  - encoding: b64
#{join("",["    ",join("\n    ",split("\n",split("-init-header-",file(fn))[0]))])}
#   content: {base64encode(reverse(split("-init-header-",file(fn)))[0])}
#{ endfor ~}
EOF
    )	  
  }

  agent_config {
    are_all_plugins_disabled = true
    is_management_disabled   = true
    is_monitoring_disabled   = true
  }

  availability_config {
    is_live_migration_preferred = null
  }

  create_vnic_details {
    assign_public_ip = false
    display_name     = "Ampere"
    hostname_label   = "ampere"
    nsg_ids          = [oci_core_network_security_group.this.id]
    subnet_id        = oci_core_subnet.this.id
  }

  shape_config {
    memory_in_gbs = 24
    ocpus         = 4
  }

  source_details {
    source_id               = data.oci_core_images.that.images.0.id
    source_type             = "image"
    boot_volume_size_in_gbs = var.use_all_storage ? var.total_storage - (var.minimum_bootvolume_size * var.number_of_micros) : 100
  }   

  lifecycle {
    ignore_changes = [source_details.0.source_id]
  }
}

data "oci_core_private_ips" "micro" {
 ip_address = oci_core_instance.micro[0].private_ip
 subnet_id  = oci_core_subnet.this.id
}
	
data "oci_core_private_ips" "ampere" {
  ip_address = oci_core_instance.ampere.private_ip
  subnet_id  = oci_core_subnet.this.id
}
	
resource "oci_core_public_ip" "that" {
  compartment_id = oci_identity_compartment.this.id
  lifetime       = "RESERVED"

  display_name  = oci_core_instance.micro[0].display_name
  private_ip_id = data.oci_core_private_ips.ampere.private_ips.0.id
}

resource "oci_core_volume_backup_policy" "this" {
  count = var.number_of_micros >= 1 ? 2 : 1 # don't backup micro-2

  compartment_id = oci_identity_compartment.this.id

  display_name = format("Monthly backup for %s", count.index == 1 ? "Ampere" : "Micro")

  schedules {
    backup_type       = "FULL"
    hour_of_day       = count.index*4
    offset_type       = "STRUCTURED"
    period            = "ONE_MONTH"
#    day_of_week       = "MONDAY"
    day_of_month      = 1
    retention_seconds = 4752000 #keep it for 2months-1day (28+27) must be a multiple of 3600
    time_zone         = "REGIONAL_DATA_CENTER_TIME"
  }
}

resource "oci_core_volume_backup_policy_assignment" "this" {
  count = var.number_of_micros >= 1 ? 2 : 1 # don't backup micro-2

  asset_id = (
    count.index == 1 ?
    oci_core_instance.ampere.boot_volume_id :
    oci_core_instance.micro[count.index].boot_volume_id
    
  )
  policy_id = oci_core_volume_backup_policy.this[count.index].id
}

# Vaults are scarce resources on OCI, take too long to create and destroy so terraform times out.
# just use a root compartment vault
# resource "oci_kms_vault" "this" {
#     #Required
#     compartment_id = oci_identity_compartment.this.id
#     display_name = "vault"
#     vault_type = "DEFAULT"
# }
	


#stopped using polocies to manage secrets and now useing oci_confg files/keys
# if you do use this method again make sure to set env variables on your instances
# bash: OCI_CLI_AUTH='instance_principal'
#https://database-heartbeat.com/2021/10/05/auth-cli/
# resource "oci_identity_dynamic_group" "this" {
#     #Required
#     compartment_id = var.tenancy_ocid
#     description = "instances group"
#     matching_rule = "All {instance.compartment.id = '${oci_identity_compartment.this.id}'}"
#     name = "instances_group"
# }

# resource "oci_identity_policy" "this" {
#     depends_on = [oci_identity_compartment.this]
#     compartment_id = var.tenancy_ocid
#     description = "Instance secret managment"
#     name = "Instance-secret-management"
#     statements = ["Allow dynamic-group 'Default'/'instances_group' to use secret-family in tenancy"]
# }

#might cause some issues if my month math is off for the backup_policy
resource "oci_core_boot_volume_backup" "this" {
    #Required
    boot_volume_id = oci_core_instance.ampere.boot_volume_id
    display_name = "Ampere clean system rollback"
    type = "FULL"
    #depends_on =[oci_core_volume_backup_policy_assignment.this, oci_core_volume_backup_policy.this, oci_core_instance.ampere]
}
