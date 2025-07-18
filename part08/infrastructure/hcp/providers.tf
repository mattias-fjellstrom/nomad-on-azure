terraform {
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.108"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}
