#---------------------------------------------------------------------------------------------------
# NSG
#---------------------------------------------------------------------------------------------------
resource "azurerm_network_security_group" "nomad_clients" {
  name                = "nsg-nomad-clients"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_subnet_network_security_group_association" "nomad_clients" {
  subnet_id                 = azurerm_subnet.all["nomad_clients"].id
  network_security_group_id = azurerm_network_security_group.nomad_clients.id
}

resource "azurerm_network_security_rule" "nomad_clients_ssh" {
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
  network_security_group_name = azurerm_network_security_group.nomad_clients.name
}

#---------------------------------------------------------------------------------------------------
# VMSS
#---------------------------------------------------------------------------------------------------
locals {
  nomad_clients = {
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
            User=root
            Group=root

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
          path    = "/etc/nomad.d/tls/${local.dns.nomad}.${var.dns_hosted_zone_name}-agent-ca.pem"
          content = file("${path.module}/tls/${local.dns.nomad}.${var.dns_hosted_zone_name}-agent-ca.pem")
        },
        {
          path    = "/etc/nomad.d/tls/global-client-${local.dns.nomad}.${var.dns_hosted_zone_name}.pem"
          content = file("${path.module}/tls/global-client-${local.dns.nomad}.${var.dns_hosted_zone_name}.pem")
        },
        {
          path    = "/etc/nomad.d/tls/global-client-${local.dns.nomad}.${var.dns_hosted_zone_name}-key.pem"
          content = file("${path.module}/tls/global-client-${local.dns.nomad}.${var.dns_hosted_zone_name}-key.pem")
        },
        {
          path    = "/etc/nomad.d/nomad.hcl"
          content = <<-EOF
            data_dir   = "/opt/nomad/data"
            plugin_dir = "/opt/nomad/plugins"
            bind_addr  = "0.0.0.0"
            datacenter = "dc1"

            tls {
              http = true
              rpc  = true

              ca_file   = "/etc/nomad.d/tls/${local.dns.nomad}.${var.dns_hosted_zone_name}-agent-ca.pem"
              cert_file = "/etc/nomad.d/tls/global-client-${local.dns.nomad}.${var.dns_hosted_zone_name}.pem"
              key_file  = "/etc/nomad.d/tls/global-client-${local.dns.nomad}.${var.dns_hosted_zone_name}-key.pem"

              verify_server_hostname = true
              verify_https_client    = true
            }

            client {
              enabled = true
            }

            plugin "nomad-driver-exec2" {
              config {
                unveil_defaults = true
                unveil_paths    = []
                unveil_by_task  = false
              }
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

data "cloudinit_config" "nomad_clients" {
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
        --remote-name https://releases.hashicorp.com/nomad/${local.nomad_clients.version}/nomad_${local.nomad_clients.version}_linux_amd64.zip
      unzip nomad_${local.nomad_clients.version}_linux_amd64.zip
      chown root:root nomad
      mv nomad /usr/bin/

      # download and install Consul
      curl \
        --silent \
        --remote-name https://releases.hashicorp.com/consul/${local.consul_servers.version}/consul_${local.consul_servers.version}_linux_amd64.zip
      unzip consul_${local.consul_servers.version}_linux_amd64.zip
      chown root:root consul
      mv consul /usr/bin/

      # create the Consul user
      useradd --system --home /etc/consul.d --shell /bin/false consul
    EOF
  }

  part {
    content_type = "text/cloud-config"
    content      = yamlencode(local.nomad_clients.cloudinit_files)
  }

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash

      mkdir -p /opt/nomad/data
      mkdir -p /opt/nomad/plugins
      mkdir -p /etc/nomad.d/tls

      mkdir -p /opt/consul
      chown -R consul:consul /opt/consul
    EOF
  }

  # Download Nomad plugins
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash

      curl \
        --silent \
        --remote-name https://releases.hashicorp.com/nomad-driver-exec2/0.1.0/nomad-driver-exec2_0.1.0_linux_amd64.zip
      unzip nomad-driver-exec2_0.1.0_linux_amd64.zip
      mv nomad-driver-exec2 /opt/nomad/plugins
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

module "nomad_clients" {
  source = "./modules/vmss"

  vmss_name           = "nomad-clients"
  resource_group_name = azurerm_resource_group.default.name
  public_key          = azurerm_ssh_public_key.servers.public_key
  identity_roles = {
    reader = {
      role  = "Reader"
      scope = azurerm_resource_group.default.id
    }
  }
  user_data_base64 = data.cloudinit_config.nomad_clients.rendered
  subnet_id        = azurerm_subnet.all["nomad_clients"].id
  azure_location   = var.azure_location

  tags = {
    nomad = "client"
  }
}
