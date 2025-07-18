variable "azure_location" {
  type        = string
  description = "Azure region where resources will be created."
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure subscription ID where resources will be created."
}

variable "private_dns_zone_name" {
  type        = string
  description = "Name of the private DNS zone to be created."
}

variable "vnet_cidr_range" {
  type        = string
  description = "CIDR range for the virtual network."
  default     = "10.0.0.0/16"
}
