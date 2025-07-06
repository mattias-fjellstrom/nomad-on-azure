output "nomad_ui_url" {
  description = "Nomad UI URL"
  value       = "http://${azurerm_public_ip.nomad_servers_lb.ip_address}:4646"
}
