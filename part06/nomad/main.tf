terraform {
  required_providers {
    nomad = {
      source  = "hashicorp/nomad"
      version = "2.5.0"
    }
  }
}

# required Nomad environment variables
provider "nomad" {}

resource "nomad_namespace" "team1" {
  name        = "team1"
  description = "Namespace for Team 1"
}

resource "nomad_acl_policy" "team1" {
  name        = "team1"
  description = "Policy for Team 1"
  rules_hcl = templatefile("${path.module}/team.hcl.tmpl", {
    namespace = nomad_namespace.team1.name
  })
}

resource "nomad_acl_token" "team1" {
  name = "team1-token"
  type = "client"
  policies = [
    nomad_acl_policy.team1.name,
  ]
}

output "token" {
  sensitive = true
  value     = nomad_acl_token.team1.secret_id
}
