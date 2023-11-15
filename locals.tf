locals {

  prefix = var.prefix != "" ? var.prefix : "${random_string.prefix.0.result}"

  tags = [
    "region:${var.region}",
    "vpc:${local.prefix}-vpc",
    "owner:${var.owner}"
  ]

  zones = length(data.ibm_is_zones.regional.zones)

  vpc_zones = {
    for zone in range(local.zones) : zone => {
      zone = "${var.region}-${zone + 1}"
    }
  }

  frontend_rules = [
    for r in var.frontend_rules : {
      name       = r.name
      direction  = r.direction
      remote     = lookup(r, "remote", null)
      ip_version = lookup(r, "ip_version", null)
      icmp       = lookup(r, "icmp", null)
      tcp        = lookup(r, "tcp", null)
      udp        = lookup(r, "udp", null)
    }
  ]


}

# vpc_zones = {
#   0 = { zone = "us-east-1" }
#   1 = { zone = "us-east-2" }
#   2 = { zone = "us-east-3" }
# }