resource "azurerm_user_assigned_identity" "default" {
  name                = var.vmss_name
  location            = var.azure_location
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "all" {
  for_each = var.identity_roles

  scope                = each.value.scope
  principal_id         = azurerm_user_assigned_identity.default.principal_id
  role_definition_name = each.value.role
}

resource "azurerm_orchestrated_virtual_machine_scale_set" "default" {
  name                = var.vmss_name
  resource_group_name = var.resource_group_name
  location            = var.azure_location

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.default.id]
  }

  platform_fault_domain_count = 1
  single_placement_group      = false
  zone_balance                = false
  zones                       = ["1", "2", "3"]

  sku_name  = var.vmss_instance_sku
  instances = var.vmss_instance_count

  user_data_base64 = var.user_data_base64

  network_interface {
    name    = "nic-${var.vmss_name}"
    primary = true

    ip_configuration {
      name      = "primary"
      subnet_id = var.subnet_id
      version   = "IPv4"

      load_balancer_backend_address_pool_ids = length(var.lb_backend_address_pool_ids) > 0 ? var.lb_backend_address_pool_ids : null

      dynamic "public_ip_address" {
        for_each = var.assign_public_ip ? [1] : []

        content {
          name = "pip-${var.vmss_name}"
        }
      }
    }
  }

  os_disk {
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
    disk_size_gb         = 30
  }

  os_profile {
    linux_configuration {
      admin_username                  = var.admin_username
      computer_name_prefix            = var.vmss_name
      disable_password_authentication = true

      admin_ssh_key {
        username   = var.admin_username
        public_key = var.public_key
      }
    }
  }

  source_image_reference {
    offer     = "ubuntu-24_04-lts"
    publisher = "canonical"
    sku       = "server"
    version   = "latest"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      instances,
    ]
  }
}
