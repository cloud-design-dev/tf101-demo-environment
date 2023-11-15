variable "region" {
  description = "The region where the VPC will be deployed"
  type        = string
  default     = "ca-tor"
}

variable "existing_resource_group" {
  description = "Existing resource group to use for the VPC."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = list(string)
  default     = ["owner:ryantiffany"]
}

variable "default_address_prefix" {
  default = "auto"
}

variable "classic_access" { default = false }
