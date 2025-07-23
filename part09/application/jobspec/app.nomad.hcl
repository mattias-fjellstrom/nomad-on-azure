job "${service_name}" {
  datacenters = ["dc1"]

  group "demo" {
    count = 3
    
    network {
      port "http" {
        to = -1
      }
    }

    service {
      name = "${service_name}"
      port = "http"

      # expose the app through nginx
      tags = ["public"]

      check {
        type     = "http"
        path     = "/"
        interval = "2s"
        timeout  = "2s"
      }
    }

    task "server" {
      env {
        PORT    = "$${NOMAD_PORT_http}"
        NODE_IP = "$${NOMAD_IP_http}"
      }

      driver = "docker"

      config {
        image = "hashicorp/demo-webapp-lb-guide"
        ports = ["http"]
      }
    }
  }
}
