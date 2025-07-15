resource "azurerm_virtual_machine" "default" {
  name                = ""
  location            = ""
  resource_group_name = ""

  vm_size = ""

  storage_os_disk {
    name          = ""
    create_option = ""
  }

  network_interface_ids = []

  identity {
    type         = "UserAssigned"
    identity_ids = []
  }



  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true
}
