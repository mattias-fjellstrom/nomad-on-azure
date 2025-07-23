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
            datacenter = "dc1"
            data_dir   = "/opt/consul"

            server  = false
            encrypt = "${trimspace(file("../../consul/gossip/gossip.key"))}"

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

            client_addr    = "0.0.0.0"
            advertise_addr = "{{ GetPrivateInterfaces | include \"network\" \"${azurerm_subnet.default.address_prefixes[0]}\" | limit 1 | attr \"address\" }}"

            ports {
              http     = -1
              https    = 8501
              grpc     = -1
              grpc_tls = 8503
            }

            auto_encrypt = {
              tls = true
            }

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
          content = file("../tls/${local.dns.nomad}.${var.dns_hosted_zone_name}-agent-ca.pem")
        },
        {
          path    = "/etc/nomad.d/tls/global-client-${local.dns.nomad}.${var.dns_hosted_zone_name}.pem"
          content = file("../tls/global-client-${local.dns.nomad}.${var.dns_hosted_zone_name}.pem")
        },
        {
          path    = "/etc/nomad.d/tls/global-client-${local.dns.nomad}.${var.dns_hosted_zone_name}-key.pem"
          content = file("../tls/global-client-${local.dns.nomad}.${var.dns_hosted_zone_name}-key.pem")
        },
        {
          path    = "/etc/nomad.d/nomad.hcl"
          content = <<-EOF
            data_dir   = "/opt/nomad/data"
            plugin_dir = "/opt/nomad/plugins"
            bind_addr  = "0.0.0.0"
            datacenter = "dc1"

            acl {
              enabled = true
            }

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

              cni_path = "/opt/cni/bin"
            }

            plugin "nomad-driver-exec2" {
              config {
                unveil_defaults = true
                unveil_paths    = []
                unveil_by_task  = false
              }
            }

            plugin "nomad-driver-podman" {
              config {
                gc {
                  container = true
                }
              }
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
      apt-get install -y curl unzip podman

      # install docker
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

      apt-get update
      apt-get install -y docker-ce docker-ce-cli containerd.io
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

      # create the Consul user
      useradd --system --home /etc/consul.d --shell /bin/false consul
    EOF
  }

  # Download and install CNI plugins
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash

      curl -L -o cni-plugins.tgz https://github.com/containernetworking/plugins/releases/download/v1.6.2/cni-plugins-linux-amd64-v1.6.2.tgz && \
        mkdir -p /opt/cni/bin && \
        tar -C /opt/cni/bin -xzf cni-plugins.tgz
      
      curl --silent \
        --remote-name https://releases.hashicorp.com/consul-cni/1.7.2/consul-cni_1.7.2_linux_amd64.zip
      unzip consul-cni_1.7.2_linux_amd64.zip
      mv consul-cni /opt/cni/bin/
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

      curl \
        --silent \
        --remote-name https://releases.hashicorp.com/nomad-driver-podman/0.6.3/nomad-driver-podman_0.6.3_linux_amd64.zip
      unzip nomad-driver-podman_0.6.3_linux_amd64.zip
      mv nomad-driver-podman /opt/nomad/plugins
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

      # Enable CNI bridge plugin (required on Ubuntu 24.04)
      modprobe bridge
    EOF
  }
}

module "nomad_clients" {
  source = "../../modules/vmss"

  vmss_name           = "nomad-clients"
  vmss_instance_sku   = "Standard_D2s_v3"
  resource_group_name = azurerm_resource_group.default.name
  public_key          = azurerm_ssh_public_key.servers.public_key
  identity_roles = {
    reader = {
      role  = "Reader"
      scope = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
    }
  }
  user_data_base64 = data.cloudinit_config.nomad_clients.rendered
  subnet_id        = azurerm_subnet.default.id
  azure_location   = var.azure_location

  assign_public_ip = false

  tags = {
    nomad = "client"
  }
}
