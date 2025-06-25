# resource "azurerm_network_interface" "nomad_lb" {
#   name                = "nic-lb-nomad"
#   location            = azurerm_resource_group.default.location
#   resource_group_name = azurerm_resource_group.default.name

#   ip_configuration {
#     name                          = "primary"
#     subnet_id                     = azurerm_subnet.servers.id
#     private_ip_address_allocation = "Dynamic"
#     primary                       = true
#   }
# }

# resource "azurerm_network_interface_backend_address_pool_association" "example" {
#   network_interface_id    = azurerm_network_interface.nomad_lb.id
#   ip_configuration_name   = "primary"
#   backend_address_pool_id = azurerm_lb_backend_address_pool.servers.id

# }

# resource "azurerm_public_ip" "nomad_lb" {
#   name                = "pip-lb-nomad"
#   resource_group_name = azurerm_resource_group.default.name
#   location            = azurerm_resource_group.default.location

#   allocation_method       = "Static"
#   idle_timeout_in_minutes = 4
#   ip_version              = "IPv4"
#   sku                     = "Standard"
#   sku_tier                = "Regional"
#   zones                   = ["1", "2", "3"]
# }

# resource "azurerm_lb" "nomad" {
#   name                = "nomad"
#   resource_group_name = azurerm_resource_group.default.name
#   location            = azurerm_resource_group.default.location
#   sku                 = "Standard"
#   sku_tier            = "Regional"

#   frontend_ip_configuration {
#     name                 = "primary"
#     public_ip_address_id = azurerm_public_ip.nomad_lb.id
#   }
# }

# resource "azurerm_lb_backend_address_pool" "servers" {
#   loadbalancer_id = azurerm_lb.nomad.id
#   name            = "nomad-servers"
# }

# resource "azurerm_lb_rule" "servers" {
#   backend_address_pool_ids       = [azurerm_lb_backend_address_pool.servers.id]
#   backend_port                   = 4646
#   disable_outbound_snat          = true
#   enable_floating_ip             = false
#   enable_tcp_reset               = false
#   frontend_ip_configuration_name = "primary"
#   frontend_port                  = 4646
#   idle_timeout_in_minutes        = 4
#   load_distribution              = "Default"
#   loadbalancer_id                = azurerm_lb.nomad.id
#   name                           = "first"
#   probe_id                       = azurerm_lb_probe.servers.id
#   protocol                       = "Tcp"
# }

# resource "azurerm_lb_probe" "servers" {
#   interval_in_seconds = 5
#   loadbalancer_id     = azurerm_lb.nomad.id
#   name                = "servers"
#   number_of_probes    = 1
#   port                = 4646
#   probe_threshold     = 1
#   protocol            = "Http"
#   request_path        = "/v1/status/leader"
# }

