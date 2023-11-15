resource "random_string" "prefix" {
  count   = var.prefix != "" ? 0 : 1
  length  = 4
  special = false
  upper   = false
  numeric = false
}

module "resource_group" {
  source                       = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.0.5"
  resource_group_name          = var.existing_resource_group == null ? "${local.prefix}-resource-group" : null
  existing_resource_group_name = var.existing_resource_group
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "ibm_is_ssh_key" "generated_key" {
  name           = "${local.prefix}-${var.region}-key"
  public_key     = tls_private_key.ssh.public_key_openssh
  resource_group = module.resource_group.resource_group_id
  tags           = concat(var.tags, local.tags)
}

resource "ibm_is_vpc" "vpc" {
  name                        = "${local.prefix}-vpc"
  resource_group              = module.resource_group.resource_group_id
  classic_access              = var.classic_access
  address_prefix_management   = var.default_address_prefix
  default_network_acl_name    = "${local.prefix}-default-network-acl"
  default_security_group_name = "${local.prefix}-default-security-group"
  default_routing_table_name  = "${local.prefix}-default-routing-table"
  tags                        = concat(var.tags, local.tags)
}

resource "ibm_is_public_gateway" "zone_1" {
  name           = "${local.prefix}-pubgw"
  resource_group = module.resource_group.resource_group_id
  vpc            = ibm_is_vpc.vpc.id
  zone           = local.vpc_zones[0].zone
  tags           = concat(var.tags, local.tags, ["zone:${local.vpc_zones[0].zone}"])
}

resource "ibm_is_subnet" "zone_1" {
  name                     = "${local.prefix}-dmz-subnet"
  resource_group           = module.resource_group.resource_group_id
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = local.vpc_zones[0].zone
  total_ipv4_address_count = "32"
  public_gateway           = ibm_is_public_gateway.zone_1.id
  tags                     = concat(var.tags, local.tags, ["zone:${local.vpc_zones[0].zone}"])
}

resource "ibm_is_subnet" "all_zones" {
  count                    = length(data.ibm_is_zones.regional.zones)
  name                     = "${local.prefix}-${local.vpc_zones[count.index].zone}-subnet"
  resource_group           = module.resource_group.resource_group_id
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = local.vpc_zones[count.index].zone
  total_ipv4_address_count = "128"
  tags                     = concat(var.tags, local.tags, ["zone:${local.vpc_zones[count.index].zone}"])
}

module "frontend_security_group" {
  source                = "terraform-ibm-modules/vpc/ibm//modules/security-group"
  version               = "1.1.1"
  create_security_group = true
  name                  = "${local.prefix}-frontend-sg"
  vpc_id                = ibm_is_vpc.vpc.id
  resource_group_id     = module.resource_group.resource_group_id
  security_group_rules  = local.frontend_rules
}

resource "ibm_is_instance" "consul_node" {
  count          = var.instance_count
  name           = "${local.prefix}-consul-${count.index}"
  vpc            = ibm_is_vpc.vpc.id
  image          = data.ibm_is_image.base.id
  profile        = var.instance_profile
  resource_group = module.resource_group.resource_group_id

  metadata_service {
    enabled            = true
    protocol           = "https"
    response_hop_limit = 5
  }

  boot_volume {
    auto_delete_volume = true
    tags               = concat(var.tags, local.tags, ["zone:${local.vpc_zones[count.index].zone}"])
  }

  primary_network_interface {
    subnet            = ibm_is_subnet.zone_1.id
    allow_ip_spoofing = var.allow_ip_spoofing
    security_groups   = [module.frontend_security_group.security_group_id[0]]
  }

  user_data = templatefile("${path.module}/instance.tftpl", {
    logging_key    = data.ibm_sm_arbitrary_secret.logging.payload,
    monitoring_key = data.ibm_sm_arbitrary_secret.monitoring.payload,
    project        = local.prefix,
    region         = var.region
  })

  zone = local.vpc_zones[0].zone
  keys = [ibm_is_ssh_key.generated_key.id]
  tags = concat(var.tags, local.tags, ["zone:${local.vpc_zones[count.index].zone}"])
}
