locals {
  basename = random_string.prefix.result
  tags     = ["region:${var.region}", "vpc:${local.basename}-vpc"]
  zones = 3
  vpc_zones = {
    for zone in range(local.zones) : zone => {
      zone = "${var.region}-${zone + 1}"
    }
  }
}

resource "random_string" "prefix" {
  length  = 4
  special = false
  upper   = false
  numeric = false
}

module "resource_group" {
  source                       = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.0.5"
  resource_group_name          = "${local.basename}-resource-group" 
}

resource "ibm_is_vpc" "vpc" {
  name                        = "${local.basename}-vpc"
  resource_group              = module.resource_group.resource_group_id
  classic_access              = var.classic_access
  address_prefix_management   = var.default_address_prefix
  default_network_acl_name    = "${local.basename}-default-network-acl"
  default_security_group_name = "${local.basename}-default-security-group"
  default_routing_table_name  = "${local.basename}-default-routing-table"
  tags                        = concat(var.tags, local.tags)
}

resource "ibm_is_public_gateway" "cluster_pgw" {
  name           = "${local.basename}-pubgw"
  resource_group = module.resource_group.resource_group_id
  vpc            = ibm_is_vpc.vpc.id
  zone           = local.vpc_zones[0].zone
  tags           = concat(local.tags, ["zone:${local.vpc_zones[0].zone}"])
}

resource "ibm_is_subnet" "dmz_subnet" {
  name                     = "${local.basename}-dmz-subnet"
  resource_group           = module.resource_group.resource_group_id
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = local.vpc_zones[0].zone
  total_ipv4_address_count = "32"
  public_gateway           = ibm_is_public_gateway.cluster_pgw.id
}

output "vpc_id" {
  value = ibm_is_vpc.vpc.id
}

output "dmz_subnet_cidr" {
value = ibm_is_subnet.dmz_subnet.ipv4_cidr_block
}

