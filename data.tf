data "ibm_resource_instance" "sm_instance" {
  name              = var.sm_instance_name
  location          = var.region
  resource_group_id = module.resource_group.resource_group_id
}

data "ibm_sm_arbitrary_secret" "logging" {
  instance_id       = data.ibm_resource_instance.sm_instance.guid
  region            = var.region
  name              = var.logging_key_secret
  secret_group_name = "ibm-vpc-automation"
}

data "ibm_sm_arbitrary_secret" "monitoring" {
  instance_id       = data.ibm_resource_instance.sm_instance.guid
  region            = var.region
  name              = var.monitoring_key_secret
  secret_group_name = "ibm-vpc-automation"
}

data "ibm_is_image" "base" {
  name = var.image_name
}

data "ibm_is_zones" "regional" {
  region = var.region
}

data "ibm_is_ssh_key" "regional" {
  name = var.existing_ssh_key
}