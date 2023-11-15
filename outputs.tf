output "vpc_id" {
  value = ibm_is_vpc.vpc.id
}

output "dmz_subnet_cidr" {
  value = ibm_is_subnet.zone_1.ipv4_cidr_block
}

output "super_secret_key" {
  value     = var.super_secret_key
  sensitive = true
}