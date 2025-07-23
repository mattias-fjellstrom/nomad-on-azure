variable "azure_subscription_id" {
  description = "The Azure subscription ID where resources will be deployed"
  type        = string
}

variable "azure_location" {
  description = "The Azure region where resources will be deployed"
  type        = string
}

variable "boundary_addr" {
  description = "The address of the HCP Boundary cluster"
  type        = string
}

variable "boundary_admin_username" {
  description = "The username for the Boundary admin user"
  type        = string
}

variable "boundary_admin_password" {
  description = "The password for the Boundary admin user"
  type        = string
  sensitive   = true
}

variable "domain" {
  type = string
}
