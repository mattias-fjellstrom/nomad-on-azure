data "azurerm_resource_group" "dns" {
  name = var.dns_resource_group_name
}

data "azurerm_dns_zone" "default" {
  name = var.dns_hosted_zone_name
}
