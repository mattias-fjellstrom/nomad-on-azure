terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.4"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.3"
    }

    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3"
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
  subscription_id = var.azure_subscription_id

  features {
    virtual_machine_scale_set {
      force_delete = true
    }
  }
}

# provider "azurerm" {
#   alias = "dns"

#   subscription_id = "b5f738fc-1560-45a9-a08e-1c8147960d20"

#   features {}
# }
