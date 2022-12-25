locals {
  protocol_number = {
    icmp   = 1
    icmpv6 = 58
    tcp    = 6
    udp    = 17
  }
  
 inbound_tcp = [
     { port = 80, description = "http (should always redirect from trafik)" }, #http
     { port = 443, description = "https" }, #https
  ]
  inbound_udp = [
      { port = 443, description = "https" }, #https
      { port = 6000, description = "restreamer srt" }, #streaming
  ]
#  { port = 53, protocol = “-1” },    # DNS
#   { port = 88, protocol = “-1” },    # Kerberos
#   { port = 123, protocol = “udp” },  # Time Sync (NTP)
#   { port = 135, protocol = “tcp” },  # RPC Endpoint Mapper
#   { port = 389, protocol = “-1” },   # LDAP
#   { port = 445, protocol = “tcp” },  # SMB
#   { port = 464, protocol = “-1” },   # Kerberos (password)
#   { port = 636, protocol = “tcp” },  # LDAP SSL
#   { port = 3268, protocol = “tcp” }, # LDAP Global Catalog
#   { port = 3269, protocol = “tcp” }  # LDAP Global Catalog SSL

  shapes = {
    flex : "VM.Standard.A1.Flex",
    micro : "VM.Standard.E2.1.Micro",
  }

  availability_domain_micro = one(
    [
      for m in data.oci_core_shapes.this :
      m.availability_domain
      if contains(m.shapes[*].name, local.shapes.micro)
    ]
  )
}

