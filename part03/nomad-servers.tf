#---------------------------------------------------------------------------------------------------
# NSG
#---------------------------------------------------------------------------------------------------
resource "azurerm_network_security_group" "nomad_servers" {
  name                = "nsg-nomad-servers"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_subnet_network_security_group_association" "nomad_servers" {
  subnet_id                 = azurerm_subnet.all["nomad_servers"].id
  network_security_group_id = azurerm_network_security_group.nomad_servers.id
}

resource "azurerm_network_security_rule" "nomad_servers_ssh" {
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
  network_security_group_name = azurerm_network_security_group.nomad_servers.name
}

#---------------------------------------------------------------------------------------------------
# VMSS
#---------------------------------------------------------------------------------------------------
locals {
  nomad_servers = {
    version = "1.10.2"

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

data "cloudinit_config" "nomad_servers" {
  gzip          = false
  base64_encode = true

  # install dependencies
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      apt-get update
      apt-get clean
      apt-get install -y curl unzip
    EOF
  }

  # Download and install Nomad + Consul and create the Nomad + Consul users
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash

      # download and install Nomad
      curl \
        --silent \
        --remote-name https://releases.hashicorp.com/nomad/${local.nomad_servers.version}/nomad_${local.nomad_servers.version}_linux_amd64.zip
      unzip nomad_${local.nomad_servers.version}_linux_amd64.zip
      chown root:root nomad
      mv nomad /usr/bin/

      # download and install Consul
      curl \
        --silent \
        --remote-name https://releases.hashicorp.com/consul/${local.consul_servers.version}/consul_${local.consul_servers.version}_linux_amd64.zip
      unzip consul_${local.consul_servers.version}_linux_amd64.zip
      chown root:root consul
      mv consul /usr/bin/

      # create the Nomad user
      useradd --system --home /etc/nomad.d --shell /bin/false nomad
      
      # create the Consul user
      useradd --system --home /etc/consul.d --shell /bin/false consul
    EOF
  }

  part {
    content_type = "text/cloud-config"
    content      = yamlencode(local.nomad_servers.cloudinit_files)
  }

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash

      mkdir -p /opt/nomad/data
      chown -R nomad:nomad /opt/nomad

      mkdir -p /opt/consul
      chown -R consul:consul /opt/consul
    EOF
  }

  # Start Nomad and Consul services
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      systemctl daemon-reload

      systemctl enable consul
      systemctl start consul

      systemctl enable nomad
      systemctl start nomad
    EOF
  }
}

module "nomad_servers" {
  source = "./modules/vmss"

  vmss_name           = "nomad-servers"
  resource_group_name = azurerm_resource_group.default.name
  public_key          = azurerm_ssh_public_key.servers.public_key
  identity_roles = {
    reader = {
      role  = "Reader"
      scope = azurerm_resource_group.default.id
    }
  }
  user_data_base64 = data.cloudinit_config.nomad_servers.rendered
  subnet_id        = azurerm_subnet.all["nomad_servers"].id
  azure_location   = var.azure_location

  tags = {
    nomad = "server"
  }
}
