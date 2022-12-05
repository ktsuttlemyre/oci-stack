provider "oci" {}

resource "oci_core_instance" "generated_oci_core_instance" {
	agent_config {
		is_management_disabled = "false"
		is_monitoring_disabled = "false"
		plugins_config {
			desired_state = "ENABLED"
			name = "Vulnerability Scanning"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Compute Instance Monitoring"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Bastion"
		}
	}
	availability_config {
		recovery_action = "RESTORE_INSTANCE"
	}
	availability_domain = "RKlJ:US-ASHBURN-AD-3"
	compartment_id = "ocid1.tenancy.oc1..aaaaaaaa5epv2c4htabogvcriwrzdgi5toijz7fqyfvwyknlkggfa2cygquq"
	create_vnic_details {
		assign_private_dns_record = "true"
		assign_public_ip = "true"
		subnet_id = "${oci_core_subnet.generated_oci_core_subnet.id}"
	}
	display_name = "instance-kqsfl"
	instance_options {
		are_legacy_imds_endpoints_disabled = "false"
	}
	is_pv_encryption_in_transit_enabled = "true"
	metadata = {
		"user_data" = "${base64encode(file("./init.sh"))}"
		"ssh_authorized_keys" = ""
	}
	shape = "VM.Standard.A1.Flex"
	shape_config {
		memory_in_gbs = "24"
		ocpus = "4"
	}
	source_details {
		boot_volume_size_in_gbs = "190"
		boot_volume_vpus_per_gb = "10"
		source_id = "ocid1.image.oc1.iad.aaaaaaaam4d2tsohvgq7cqilhtcnlvp2zmzatb57xuprljhkvqgon73uzeqq"
		source_type = "image"
	}
}

resource "oci_core_vcn" "generated_oci_core_vcn" {
	cidr_block = "10.0.0.0/16"
	compartment_id = "ocid1.tenancy.oc1..aaaaaaaa5epv2c4htabogvcriwrzdgi5toijz7fqyfvwyknlkggfa2cygquq"
	display_name = "vcn-kqsfl"
	dns_label = "vcn10301727"
}

resource "oci_core_subnet" "generated_oci_core_subnet" {
	cidr_block = "10.0.0.0/24"
	compartment_id = "ocid1.tenancy.oc1..aaaaaaaa5epv2c4htabogvcriwrzdgi5toijz7fqyfvwyknlkggfa2cygquq"
	display_name = "subnet-kqsfl"
	dns_label = "subnet10301727"
	route_table_id = "${oci_core_vcn.generated_oci_core_vcn.default_route_table_id}"
	vcn_id = "${oci_core_vcn.generated_oci_core_vcn.id}"
}

resource "oci_core_internet_gateway" "generated_oci_core_internet_gateway" {
	compartment_id = "ocid1.tenancy.oc1..aaaaaaaa5epv2c4htabogvcriwrzdgi5toijz7fqyfvwyknlkggfa2cygquq"
	display_name = "Internet Gateway vcn-kqsfl"
	enabled = "true"
	vcn_id = "${oci_core_vcn.generated_oci_core_vcn.id}"
}

resource "oci_core_default_route_table" "generated_oci_core_default_route_table" {
	route_rules {
		destination = "0.0.0.0/0"
		destination_type = "CIDR_BLOCK"
		network_entity_id = "${oci_core_internet_gateway.generated_oci_core_internet_gateway.id}"
	}
	manage_default_resource_id = "${oci_core_vcn.generated_oci_core_vcn.default_route_table_id}"
}
