#---------------------------------------------------------------------------------------------------
# NGINX
#---------------------------------------------------------------------------------------------------
resource "nomad_job" "nginx" {
  jobspec = templatefile("${path.module}/jobspec/nginx.nomad.hcl", {
    domain = var.dns_hosted_zone_name
  })
}

#---------------------------------------------------------------------------------------------------
# webapp1
#---------------------------------------------------------------------------------------------------
resource "nomad_job" "webapp1" {
  jobspec = templatefile("${path.module}/jobspec/app.nomad.hcl", {
    service_name = "webapp1"
  })
}

resource "azurerm_dns_cname_record" "webapp1" {
  name                = "webapp1"
  resource_group_name = data.azurerm_dns_zone.default.resource_group_name
  zone_name           = data.azurerm_dns_zone.default.name
  ttl                 = 60
  record              = "appgw.${data.azurerm_dns_zone.default.name}"
}

#---------------------------------------------------------------------------------------------------
# webapp2
#---------------------------------------------------------------------------------------------------
resource "nomad_job" "webapp2" {
  jobspec = templatefile("${path.module}/jobspec/app.nomad.hcl", {
    service_name = "webapp2"
  })
}

resource "azurerm_dns_cname_record" "webapp2" {
  name                = "webapp2"
  resource_group_name = data.azurerm_dns_zone.default.resource_group_name
  zone_name           = data.azurerm_dns_zone.default.name
  ttl                 = 60
  record              = "appgw.${data.azurerm_dns_zone.default.name}"
}
