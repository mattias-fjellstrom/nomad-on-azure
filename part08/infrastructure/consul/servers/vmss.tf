locals {
  version = "1.21.2"

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
        content = file("../tls/consul-agent-ca.pem")
      },
      {
        path    = "/etc/consul.d/tls/dc1-server-consul-0.pem"
        content = file("../tls/dc1-server-consul-0.pem")
      },
      {
        path    = "/etc/consul.d/tls/dc1-server-consul-0-key.pem"
        content = file("../tls/dc1-server-consul-0-key.pem")
      },
      {
        path    = "/etc/consul.d/consul.hcl"
        content = <<-EOF
          data_dir  = "/opt/consul"
          log_level = "info"

          datacenter = "dc1"
          
          encrypt                 = "${trimspace(file("../gossip/gossip.key"))}"
          encrypt_verify_incoming = true
          encrypt_verify_outgoing = true
          
          server = true
          
          client_addr = "{{ GetPrivateInterfaces | include \"network\" \"${azurerm_subnet.default.address_prefixes[0]}\" | limit 1 | attr \"address\" }}"
          
          ports {
            grpc     = -1
            grpc_tls = 8503
            http     = -1
            https    = 8501
            dns      = 8600
          }

          advertise_addr = "{{ GetPrivateInterfaces | include \"network\" \"${azurerm_subnet.default.address_prefixes[0]}\" | limit 1 | attr \"address\" }}"
          bind_addr      = "{{ GetPrivateInterfaces | include \"network\" \"${azurerm_subnet.default.address_prefixes[0]}\" | limit 1 | attr \"address\" }}"

          bootstrap_expect = 3
          retry_join = [
            "provider=azure tag_name=consul tag_value=server subscription_id=${data.azurerm_client_config.current.subscription_id}"
          ]

          tls {
            defaults {
              verify_incoming = true
              verify_outgoing = true
              ca_file         = "/etc/consul.d/tls/consul-agent-ca.pem"
              cert_file       = "/etc/consul.d/tls/dc1-server-consul-0.pem"
              key_file        = "/etc/consul.d/tls/dc1-server-consul-0-key.pem"
            }

            internal_rpc {
              verify_server_hostname = true
            }
          }
          
          auto_encrypt {
            allow_tls = true
          }

          addresses {
            https = "0.0.0.0"
          }

          connect {
            enabled = true
          }

          ui_config {
            enabled = true
          }
        EOF
      }
    ]
  }
}

data "cloudinit_config" "consul_servers" {
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

  # Install Consul
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash

      # download and install Consul
      curl \
        --silent \
        --remote-name https://releases.hashicorp.com/consul/${local.version}/consul_${local.version}_linux_amd64.zip
      unzip consul_${local.version}_linux_amd64.zip
      chown root:root consul
      mv consul /usr/bin/

      # create the Consul user
      useradd --system --home /etc/consul.d --shell /bin/false consul
    EOF
  }

  part {
    content_type = "text/cloud-config"
    content      = yamlencode(local.cloudinit_files)
  }

  # Start the Consul service
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash

      mkdir -p /opt/consul
      chown -R consul:consul /opt/consul
    EOF
  }

  # Start the Consul service
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      systemctl daemon-reload
      systemctl enable consul
      systemctl start consul
    EOF
  }
}

module "consul_servers" {
  source = "../../modules/vmss"

  vmss_name           = "consul-servers"
  resource_group_name = azurerm_resource_group.default.name
  public_key          = azurerm_ssh_public_key.servers.public_key
  identity_roles = {
    reader = {
      role  = "Reader"
      scope = azurerm_resource_group.default.id
    }
  }
  user_data_base64 = data.cloudinit_config.consul_servers.rendered
  subnet_id        = azurerm_subnet.default.id
  azure_location   = var.azure_location

  lb_backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.private.id,
  ]
  assign_public_ip = false

  tags = {
    consul = "server"
  }
}

resource "null_resource" "tag" {
  depends_on = [module.consul_servers]

  provisioner "local-exec" {
    working_dir = "${path.module}/scripts"
    command     = "./tag.sh"
  }
}
