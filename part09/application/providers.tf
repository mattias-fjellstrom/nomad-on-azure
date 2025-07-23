terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.3"
    }

    nomad = {
      source  = "hashicorp/nomad"
      version = "~> 2.5"
    }
  }
}

provider "azurerm" {
  subscription_id = var.azure_subscription_id

  features {}
}

provider "nomad" {}
