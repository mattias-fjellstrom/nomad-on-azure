variable "azure_location" {
  description = "Azure location for the resources"
  type        = string
}

variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "server_count" {
  type        = number
  description = "Number of Nomad server instances in the scale set"
  default     = 3
}

variable "virtual_machine_sku_name" {
  type        = string
  description = "The SKU name for the virtual machines in the scale set"
  default     = "Standard_D2s_v3"
}
