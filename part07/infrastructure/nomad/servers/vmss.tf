locals {
  consul = {
    version = "1.21.2"
  }

  nomad = {
    version = "1.10.2+ent"

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
          path    = "/etc/consul.d/tls/consul-agent-ca.pem"
          content = file("../../consul/tls/consul-agent-ca.pem")
        },
        {
          path    = "/etc/consul.d/consul.hcl"
          content = <<-EOF
            data_dir   = "/opt/consul"
            log_level  = "info"
            datacenter = "dc1"

            encrypt = "${trimspace(file("../../consul/gossip/gossip.key"))}"

            server = false

            client_addr = "0.0.0.0"

            ports {
              grpc     = -1
              grpc_tls = 8503
              http     = -1
              https    = 8501
            }

            advertise_addr = "{{ GetPrivateInterfaces | include \"network\" \"${azurerm_subnet.default.address_prefixes[0]}\" | limit 1 | attr \"address\" }}"

            retry_join = [
              "provider=azure tag_name=consul tag_value=server subscription_id=${data.azurerm_client_config.current.subscription_id}"
            ]

            tls {
              defaults {
                ca_file         = "/etc/consul.d/tls/consul-agent-ca.pem"
                verify_incoming = false
                verify_outgoing = true
              }

              internal_rpc {
                verify_server_hostname = true
              }
            }

            auto_encrypt = {
              tls = true
            }
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
          path    = "/etc/nomad.d/license/nomad.hclic"
          content = file("../license/nomad.hclic")
        },
        {
          path    = "/etc/nomad.d/tls/${local.dns.nomad}.${var.dns_hosted_zone_name}-agent-ca.pem"
          content = file("../tls/${local.dns.nomad}.${var.dns_hosted_zone_name}-agent-ca.pem")
        },
        {
          path    = "/etc/nomad.d/tls/global-server-${local.dns.nomad}.${var.dns_hosted_zone_name}.pem"
          content = file("../tls/global-server-${local.dns.nomad}.${var.dns_hosted_zone_name}.pem")
        },
        {
          path    = "/etc/nomad.d/tls/global-server-${local.dns.nomad}.${var.dns_hosted_zone_name}-key.pem"
          content = file("../tls/global-server-${local.dns.nomad}.${var.dns_hosted_zone_name}-key.pem")
        },
        {
          path    = "/etc/nomad.d/nomad.hcl"
          content = <<-EOF
            data_dir   = "/opt/nomad/data"
            bind_addr  = "0.0.0.0"
            datacenter = "dc1"

            acl {
              enabled = true
            }

            tls {
              http = true
              rpc  = true

              ca_file   = "/etc/nomad.d/tls/${local.dns.nomad}.${var.dns_hosted_zone_name}-agent-ca.pem"
              cert_file = "/etc/nomad.d/tls/global-server-${local.dns.nomad}.${var.dns_hosted_zone_name}.pem"
              key_file  = "/etc/nomad.d/tls/global-server-${local.dns.nomad}.${var.dns_hosted_zone_name}-key.pem"

              verify_server_hostname = true
              verify_https_client    = true
            }

            ui {
              enabled = true
            }

            server {
              enabled          = true
              bootstrap_expect = 3
              encrypt          = "${random_bytes.nomad_gossip_key.base64}"
              license_path     = "/etc/nomad.d/license/nomad.hclic"
            }

            consul {
              ssl        = true
              verify_ssl = false
              address    = "127.0.0.1:8501"
              ca_file    = "/etc/consul.d/tls/consul-agent-ca.pem"
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
        --remote-name https://releases.hashicorp.com/nomad/${local.nomad.version}/nomad_${local.nomad.version}_linux_amd64.zip
      unzip nomad_${local.nomad.version}_linux_amd64.zip
      chown root:root nomad
      mv nomad /usr/bin/

      # download and install Consul
      curl \
        --silent \
        --remote-name https://releases.hashicorp.com/consul/${local.consul.version}/consul_${local.consul.version}_linux_amd64.zip
      unzip consul_${local.consul.version}_linux_amd64.zip
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
    content      = yamlencode(local.nomad.cloudinit_files)
  }

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash

      mkdir -p /opt/nomad/data
      chown -R nomad:nomad /opt/nomad
      chown -R nomad:nomad /etc/nomad.d

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

      systemctl restart systemd-resolved

      systemctl enable consul
      systemctl start consul

      systemctl enable nomad
      systemctl start nomad
    EOF
  }
}

module "nomad_servers" {
  source = "../../modules/vmss"

  vmss_name           = "nomad-servers"
  resource_group_name = azurerm_resource_group.default.name
  public_key          = azurerm_ssh_public_key.servers.public_key
  identity_roles = {
    reader = {
      role  = "Reader"
      scope = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
    }
  }
  user_data_base64 = data.cloudinit_config.nomad_servers.rendered
  subnet_id        = azurerm_subnet.default.id
  azure_location   = var.azure_location

  lb_backend_address_pool_ids = [azurerm_lb_backend_address_pool.nomad_servers.id]
  assign_public_ip            = false

  tags = {
    nomad = "server"
  }
}
