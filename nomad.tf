#---------------------------------------------------------------------------------------------------
# NSG
#---------------------------------------------------------------------------------------------------
resource "azurerm_network_security_group" "nomad" {
  name                = "nsg-nomad"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_subnet_network_security_group_association" "nomad" {
  subnet_id                 = azurerm_subnet.nomad.id
  network_security_group_id = azurerm_network_security_group.nomad.id
}

resource "azurerm_network_security_rule" "nomad_ssh" {
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
  network_security_group_name = azurerm_network_security_group.nomad.name
}

#---------------------------------------------------------------------------------------------------
# VMSS
#---------------------------------------------------------------------------------------------------
locals {
  nomad = {
    vmss_name = "vmss-nomad-servers"

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

            retry_join = [
              "provider=azure tag_name=consul tag_value=server subscription_id=${data.azurerm_client_config.current.subscription_id}"
            ]
          EOF
        },
        {
          path    = "/etc/systemd/system/nomad.service"
          content = <<-EOF
            [Unit]
            Description=Nomad
            Documentation=https://nomadproject.io/docs/
            Wants=consul.service
            After=consul.service

            [Service]
            User=nomad
            Group=nomad

            Type=notify
            EnvironmentFile=-/etc/nomad.d/nomad.env
            ExecReload=/bin/kill -HUP $MAINPID
            ExecStart=/usr/bin/nomad agent -config /etc/nomad.d
            KillMode=process
            KillSignal=SIGINT
            LimitNOFILE=65536
            LimitNPROC=infinity
            Restart=on-failure
            RestartSec=2

            TasksMax=infinity

            OOMScoreAdjust=-1000

            [Install]
            WantedBy=multi-user.target
          EOF
        },
        {
          path    = "/etc/nomad.d/nomad.hcl"
          content = <<-EOF
            data_dir  = "/opt/nomad/data"
            bind_addr = "0.0.0.0"

            datacenter = "dc1"

            tls {
              http = false
              rpc  = false
            }

            ports {
              http = 4646
              rpc  = 4647
              serf = 4648
            }

            server {
              enabled          = true
              bootstrap_expect = 3
            }

            consul {
              address = "127.0.0.1:8500"
            }
          EOF
        }
      ]
    }
  }
}

data "cloudinit_config" "nomad" {
  gzip          = false
  base64_encode = true

  # Install Nomad and Consul
  part {
    filename     = "install-nomad.sh"
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      wget -O - https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
      apt update && apt install -y nomad consul
    EOF
  }

  part {
    content_type = "text/cloud-config"
    content      = yamlencode(local.nomad.cloudinit_files)
  }

  # Start the Nomad service
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash

      mkdir -p /opt/nomad/data
      chown -R nomad:nomad /opt/nomad

      mkdir -p /opt/consul
      chown -R consul:consul /opt/consul
      chown -R consul:consul /etc/consul.d
      chmod 640 /etc/consul.d/consul.hcl

      systemctl daemon-reload

      systemctl enable consul
      systemctl start consul

      systemctl enable nomad
      systemctl start nomad
    EOF
  }
}

resource "azurerm_user_assigned_identity" "nomad" {
  name                = "nomad"
  location            = var.azure_location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_role_assignment" "nomad" {
  scope                = azurerm_resource_group.default.id
  principal_id         = azurerm_user_assigned_identity.nomad.principal_id
  role_definition_name = "Reader"
}

resource "azurerm_orchestrated_virtual_machine_scale_set" "nomad" {
  name                = local.nomad.vmss_name
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

  user_data_base64 = data.cloudinit_config.nomad.rendered

  network_interface {
    name    = "nic-nomad-servers"
    primary = true

    ip_configuration {
      name      = "primary"
      subnet_id = azurerm_subnet.nomad.id
      version   = "IPv4"

      # load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.nomad.id]

      public_ip_address {
        name = "pip-nomad-servers"
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
      computer_name_prefix            = "nomadsrv"
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
    nomad = "server"
  }

  lifecycle {
    ignore_changes = [
      instances,
    ]
  }
}
