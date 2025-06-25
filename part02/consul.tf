#---------------------------------------------------------------------------------------------------
# NSG
#---------------------------------------------------------------------------------------------------
resource "azurerm_network_security_group" "consul" {
  name                = "nsg-consul"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_subnet_network_security_group_association" "consul" {
  subnet_id                 = azurerm_subnet.consul.id
  network_security_group_id = azurerm_network_security_group.consul.id
}

resource "azurerm_network_security_rule" "consul_ssh" {
  name                        = "allow_ssh"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["22"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.default.name
  network_security_group_name = azurerm_network_security_group.consul.name
}

#---------------------------------------------------------------------------------------------------
# VMSS
#---------------------------------------------------------------------------------------------------
locals {
  consul = {
    vmss_name = "vmss-consul-servers"

    cloudinit_files = {
      write_files = [
        {
          path    = "/etc/systemd/system/consul.service"
          content = <<-EOF
            [Unit]
            Description="HashiCorp Consul - A service mesh solution"
            Documentation=https://www.consul.io/
            Requires=network-online.target
            After=network-online.target
            ConditionFileNotEmpty=/etc/consul.d/consul.hcl

            [Service]
            EnvironmentFile=-/etc/consul.d/consul.env
            User=consul
            Group=consul
            ExecStart=/usr/bin/consul agent -config-dir=/etc/consul.d/
            ExecReload=/bin/kill --signal HUP $MAINPID
            KillMode=process
            KillSignal=SIGTERM
            Restart=on-failure
            LimitNOFILE=65536

            [Install]
            WantedBy=multi-user.target
          EOF
        },
        {
          path    = "/etc/consul.d/consul.hcl"
          content = <<-EOF
            datacenter = "dc1"
            data_dir   = "/opt/consul"

            server           = true
            bootstrap_expect = 3

            retry_join = [
              "provider=azure tag_name=consul tag_value=server subscription_id=${data.azurerm_client_config.current.subscription_id}"
            ]
          EOF
        }
      ]
    }
  }
}

data "cloudinit_config" "consul" {
  gzip          = false
  base64_encode = true

  # Install Consul
  part {
    filename     = "install-consul.sh"
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      wget -O - https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
      apt update && apt install -y consul
    EOF
  }

  part {
    content_type = "text/cloud-config"
    content      = yamlencode(local.consul.cloudinit_files)
  }

  # Start the Consul service
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash

      mkdir -p /opt/consul
      chown -R consul:consul /opt/consul
      chown -R consul:consul /etc/consul.d
      chmod 640 /etc/consul.d/consul.hcl

      systemctl daemon-reload
      systemctl enable consul
      systemctl start consul
    EOF
  }
}

resource "azurerm_user_assigned_identity" "consul" {
  name                = "consul"
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_role_assignment" "consul" {
  scope                = azurerm_resource_group.default.id
  principal_id         = azurerm_user_assigned_identity.consul.principal_id
  role_definition_name = "Reader"
}

resource "azurerm_orchestrated_virtual_machine_scale_set" "consul" {
  name                = local.consul.vmss_name
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.consul.id]
  }

  platform_fault_domain_count = 1
  single_placement_group      = false
  zone_balance                = false
  zones                       = ["1", "2", "3"]

  instances = 3

  sku_name = "Standard_D2s_v3"

  user_data_base64 = data.cloudinit_config.consul.rendered

  network_interface {
    name    = "nic-consul-servers"
    primary = true

    ip_configuration {
      name      = "primary"
      subnet_id = azurerm_subnet.consul.id
      version   = "IPv4"

      public_ip_address {
        name = "pip-consul-servers"
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
      admin_username                  = "azureuser"
      computer_name_prefix            = "consulsrv"
      disable_password_authentication = true

      admin_ssh_key {
        username   = "azureuser"
        public_key = azurerm_ssh_public_key.servers.public_key
      }
    }
  }

  source_image_reference {
    offer     = "ubuntu-24_04-lts"
    publisher = "canonical"
    sku       = "server"
    version   = "latest"
  }

  tags = {
    consul = "server"
  }

  lifecycle {
    ignore_changes = [
      instances,
    ]
  }
}
