variable "admin_username" {
  type        = string
  description = "The admin username for the VMSS instances"
  default     = "azureuser"
}

variable "assign_public_ip" {
  type        = bool
  description = "Whether to assign a public IP address to the VMSS instances"
  default     = true
}

variable "azure_location" {
  description = "Azure location for the resources"
  type        = string
}

variable "lb_backend_address_pool_ids" {
  type        = set(string)
  description = "A set of backend address pool IDs for the load balancer to associate with"
  default     = []
}

variable "identity_roles" {
  type = map(object({
    role  = string
    scope = string
  }))
  description = "Built-in role assignments to be created for the user-assigned identity"
}

variable "public_key" {
  type        = string
  description = "The public SSH key to be used for VMSS instances"
}

variable "resource_group_name" {
  description = "The name of the resource group where the VMSS will be created"
  type        = string
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet where the VMSS will be deployed"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the VMSS"
}

variable "vmss_instance_count" {
  type        = number
  description = "The number of instances in the VMSS"
  default     = 3
}

variable "vmss_instance_sku" {
  type        = string
  description = "The SKU for the VMSS instances"
  default     = "Standard_B2ts_v2"
  # default     = "Standard_D2s_v3"
}

variable "vmss_name" {
  type        = string
  description = "The name of the VMSS to be created"
}

variable "user_data_base64" {
  type        = string
  description = "Base64 encoded user data script to be executed on VMSS instances"
}
