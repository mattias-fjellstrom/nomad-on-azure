resource "tls_private_key" "servers" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "pricate_key" {
  content         = tls_private_key.servers.private_key_pem
  filename        = "${path.module}/ssh_keys/nomad-servers.pem"
  file_permission = "0400"
}

resource "azurerm_ssh_public_key" "servers" {
  name                = "nomad-servers"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  public_key          = tls_private_key.servers.public_key_openssh
}
