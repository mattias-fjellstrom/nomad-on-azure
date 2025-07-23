variable "boundary_admin_username" {
  description = "The username for the Boundary admin user."
  type        = string
}

variable "boundary_admin_password" {
  description = "The password for the Boundary admin user."
  type        = string
  sensitive   = true
}
