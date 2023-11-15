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

variable "existing_ssh_key" {
  description = "Existing SSH key to use for the VPC."
  type        = string
  default     = ""
}

variable "allow_ip_spoofing" {
  description = "Allow IP Spoofing"
  type        = bool
  default     = true
}

variable "instance_profile" {
  description = "The profile to use for the instance"
  type        = string
  default     = "bx2-4x16"
}

variable "image_name" {
  description = "The name of an existing OS image to use. You can list available images with the command 'ibmcloud is images'."
  type        = string
  default     = "ibm-ubuntu-22-04-2-minimal-amd64-1"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = list(string)
  default     = ["terraform101"]
}

variable "default_address_prefix" {
  default = "auto"
}

variable "classic_access" { default = false }
variable "instance_count" { default = 3 }
variable "monitoring_key_secret" {}
variable "logging_key_secret" {}

variable "owner" {
  description = "Value for the owner tag"
  type        = string
}

variable "prefix" {
  description = "Prefix to use for resource names"
  type        = string
}

variable "super_secret_key" {
  description = "Super secret key to use super secret things"
  sensitive   = true
  type        = string
}

variable "sm_instance_name" {
  description = "Name of the Secrets Manager instance where the logging and monitoring secrets are stored"
  type        = string
}

variable "frontend_rules" {
  description = "A list of security group rules to be added to the Frontend security group"
  type = list(
    object({
      name      = string
      direction = string
      remote    = string
      tcp = optional(
        object({
          port_max = optional(number)
          port_min = optional(number)
        })
      )
      udp = optional(
        object({
          port_max = optional(number)
          port_min = optional(number)
        })
      )
      icmp = optional(
        object({
          type = optional(number)
          code = optional(number)
        })
      )
    })
  )

  validation {
    error_message = "Security group rules can only have one of `icmp`, `udp`, or `tcp`."
    condition = (var.frontend_rules == null || length(var.frontend_rules) == 0) ? true : length(distinct(
      # Get flat list of results
      flatten([
        # Check through rules
        for rule in var.frontend_rules :
        # Return true if there is more than one of `icmp`, `udp`, or `tcp`
        true if length(
          [
            for type in ["tcp", "udp", "icmp"] :
            true if rule[type] != null
          ]
        ) > 1
      ])
    )) == 0 # Checks for length. If all fields all correct, array will be empty
  }

  validation {
    error_message = "Security group rule direction can only be `inbound` or `outbound`."
    condition = (var.frontend_rules == null || length(var.frontend_rules) == 0) ? true : length(distinct(
      flatten([
        # Check through rules
        for rule in var.frontend_rules :
        # Return false if direction is not valid
        false if !contains(["inbound", "outbound"], rule.direction)
      ])
    )) == 0
  }

  validation {
    error_message = "Security group rule names must match the regex pattern ^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$."
    condition = (var.frontend_rules == null || length(var.frontend_rules) == 0) ? true : length(distinct(
      flatten([
        # Check through rules
        for rule in var.frontend_rules :
        # Return false if direction is not valid
        false if !can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", rule.name))
      ])
    )) == 0
  }

  default = [
    {
      name       = "inbound-http"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 80
        port_max = 80
      }
    },
    {
      name       = "inbound-https"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 443
        port_max = 443
      }
    },
    {
      name       = "inbound-ssh"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 22
        port_max = 22
      }
    },
    {
      name       = "inbound-icmp"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      icmp = {
        code = 0
        type = 8
      }
    },
    {
      name       = "http-outbound"
      direction  = "outbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 80
        port_max = 80
      }
    },
    {
      name       = "https-outbound"
      direction  = "outbound"
      remote     = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 443
        port_max = 443
      }
    },
    {
      name       = "iaas-services-outbound"
      direction  = "outbound"
      remote     = "161.26.0.0/16"
      ip_version = "ipv4"
    },
    {
      name       = "cloud-services-outbound"
      direction  = "outbound"
      remote     = "166.8.0.0/14"
      ip_version = "ipv4"
    }
  ]
}