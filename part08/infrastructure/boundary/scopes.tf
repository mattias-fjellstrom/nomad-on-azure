resource "boundary_scope" "organization" {
  name     = "nomad-on-azure"
  scope_id = "global"

  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_scope" "project" {
  name     = "azure"
  scope_id = boundary_scope.organization.id

  auto_create_admin_role   = true
  auto_create_default_role = true
}
