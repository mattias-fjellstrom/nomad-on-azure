terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.4"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.36"
    }

    boundary = {
      source  = "hashicorp/boundary"
      version = "~> 1.3"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.azure_subscription_id
}

provider "boundary" {
  addr                   = var.boundary_addr
  auth_method_login_name = var.boundary_admin_username
  auth_method_password   = var.boundary_admin_password
}
