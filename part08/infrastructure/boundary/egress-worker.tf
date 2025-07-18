resource "boundary_worker" "egress" {
  scope_id                    = boundary_scope.project.id
  name                        = "azure-egress-worker"
  worker_generated_auth_token = ""
}

locals {
  egress_worker_cloudinit_files = {
    write_files = [
      {
        path    = "/etc/systemd/system/boundary.service"
        content = <<-EOF
          [Unit]
          Description=Boundary Worker Service
          
          [Service]
          ExecStart=/usr/bin/boundary server -config /etc/boundary.d/worker.hcl
          User=boundary
          Group=boundary
          LimitMEMLOCK=infinity
          Capabilities=CAP_IPC_LOCK+ep
          CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
          
          [Install]
          WantedBy=multi-user.target
        EOF
      },
      {
        path    = "/etc/boundary.d/worker.hcl"
        content = <<-EOF
          disable_mlock = true

          listener "tcp" {
            address = "0.0.0.0:9202"
            purpose = "proxy"
          }

          worker {
            public_addr       = "PUBLIC_IP"
            initial_upstreams = ["10.0.100.4:9202"]

            auth_storage_path                     = "/etc/boundary.d/worker"
            controller_generated_activation_token = "${boundary_worker.egress.controller_generated_activation_token}"
            
            tags {
              type = ["worker", "azure", "egress"]
            }
          }
        EOF
      }
    ]
  }
}

data "cloudinit_config" "egress_worker" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      apt-get update
      apt-get clean
      apt-get install -y curl unzip
    EOF
  }

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash

      # download and install Boundary
      curl \
        --silent \
        --remote-name https://releases.hashicorp.com/boundary/${local.version}/boundary_${local.version}_linux_amd64.zip
      unzip boundary_${local.version}_linux_amd64.zip
      chown root:root boundary
      mv boundary /usr/bin/

      # create the Boundary user
      useradd --system --home /etc/boundary.d --shell /bin/false boundary
    EOF
  }

  part {
    content_type = "text/cloud-config"
    content      = yamlencode(local.egress_worker_cloudinit_files)
  }

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash

      IP=$(curl \
        -sH "Metadata:true" \
        --noproxy "*" \
        "http://169.254.169.254/metadata/instance/network/interface?api-version=2020-09-01" | \
          jq -r .[0].ipv4.ipAddress[0].privateIpAddress)

      sed -i "s/PUBLIC_IP/$IP/g" /etc/boundary.d/worker.hcl
    EOF
  }

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash

      mkdir -p /etc/boundary.d/worker
      chown -R boundary:boundary /etc/boundary.d/worker
    EOF
  }

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      systemctl daemon-reload
      systemctl enable boundary
      systemctl start boundary
    EOF
  }
}

module "egress_workers" {
  source = "../modules/vmss"

  vmss_name           = "boundary-egress-worker"
  vmss_instance_count = 1
  resource_group_name = azurerm_resource_group.default.name
  public_key          = azurerm_ssh_public_key.servers.public_key

  identity_roles = {
    reader = {
      role  = "Reader"
      scope = azurerm_resource_group.default.id
    }
  }

  vmss_instance_sku = "Standard_D2s_v3"

  user_data_base64 = data.cloudinit_config.egress_worker.rendered
  subnet_id        = azurerm_subnet.egress_workers.id
  azure_location   = var.azure_location

  assign_public_ip = false

  tags = {
    boundary = "egress-worker"
  }

  depends_on = [
    module.ingress_workers,
  ]
}
