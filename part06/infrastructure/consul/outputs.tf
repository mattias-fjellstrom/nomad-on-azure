output "consul_web_ui" {
  value = "http://${azurerm_public_ip.lb.ip_address}:8500/ui"
}
