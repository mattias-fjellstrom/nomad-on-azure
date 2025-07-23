data "azurerm_resource_group" "dns" {
  name = var.dns_resource_group_name
}

data "azurerm_private_dns_zone" "default" {
  name = var.dns_hosted_zone_name
}

locals {
  dns = {
    nomad = "nomad"
  }
}

resource "azurerm_private_dns_a_record" "default" {
  name                = local.dns.nomad
  zone_name           = data.azurerm_private_dns_zone.default.name
  resource_group_name = data.azurerm_resource_group.dns.name
  ttl                 = "60"

  records = [
    azurerm_lb.nomad_servers.frontend_ip_configuration[0].private_ip_address
  ]
}
