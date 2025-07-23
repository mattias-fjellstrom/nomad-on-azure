resource "azurerm_private_dns_resolver_forwarding_rule" "consul" {
  name                      = "consul-dns"
  dns_forwarding_ruleset_id = "/subscriptions/4b49e707-75d3-4789-9964-296cb39305d3/resourceGroups/rg-shared-platform/providers/Microsoft.Network/dnsForwardingRulesets/default"
  domain_name               = "consul."

  target_dns_servers {
    ip_address = azurerm_lb.private.frontend_ip_configuration[0].private_ip_address
    port       = 53
  }
}

data "azurerm_resource_group" "dns" {
  name = var.dns_resource_group_name
}

data "azurerm_private_dns_zone" "default" {
  name = var.dns_hosted_zone_name
}

resource "azurerm_private_dns_a_record" "default" {
  name                = "consul"
  zone_name           = data.azurerm_private_dns_zone.default.name
  resource_group_name = data.azurerm_resource_group.dns.name
  ttl                 = "60"

  records = [
    azurerm_lb.private.frontend_ip_configuration[0].private_ip_address,
  ]
}
