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
        path    = "/etc/consul.d/consul.hcl"
        content = <<-EOF
          datacenter = "dc1"
          data_dir   = "/opt/consul"

          server           = true
          bootstrap_expect = 3

          addresses {
            http = "0.0.0.0"
          }

          retry_join = [
            "provider=azure tag_name=consul tag_value=server subscription_id=${data.azurerm_client_config.current.subscription_id}"
          ]

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
  source = "../modules/vmss"

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

  lb_backend_address_pool_ids = [azurerm_lb_backend_address_pool.servers.id]
  assign_public_ip            = false

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
