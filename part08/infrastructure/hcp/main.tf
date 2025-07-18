resource "hcp_project" "default" {
  name        = "nomad-on-azure"
  description = "Resources related to the Nomad on Azure project"
}

resource "hcp_boundary_cluster" "default" {
  cluster_id = "boundary-cluster-${var.boundary_admin_username}"
  project_id = hcp_project.default.resource_id
  tier       = "Plus"

  username = var.boundary_admin_username
  password = var.boundary_admin_password

  maintenance_window_config {
    upgrade_type = "SCHEDULED"
    day          = "FRIDAY"
    start        = 4
    end          = 8
  }
}

resource "local_sensitive_file" "terraform_tfvars" {
  filename = "../boundary/terraform.tfvars"
  content  = <<-EOT
    boundary_addr           = "${hcp_boundary_cluster.default.cluster_url}"
    boundary_admin_username = "${var.boundary_admin_username}"
    boundary_admin_password = "${var.boundary_admin_password}"
  EOT
}
