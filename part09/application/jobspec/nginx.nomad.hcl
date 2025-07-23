job "nginx" {
  datacenters = ["dc1"]

  group "nginx" {
    count = 1

    network {
      port "http" {
        static = 8080
      }
    }

    service {
      name = "nginx"
      port = "http"
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx"

        ports = ["http"]

        volumes = [
          "local:/etc/nginx/conf.d",
        ]
      }

      template {
        data = <<EOF
{{- range services -}}
{{- if .Tags | contains "public" -}}
upstream {{ .Name }} {
{{- range service .Name }}
  server {{ .Address }}:{{ .Port }};
{{ end -}}
}
{{ end -}}
{{ end }}

{{- range services -}}
{{- if .Tags | contains "public" -}}
server {
    listen 8080;
    server_name {{ .Name }}.${domain};
    location / {
        proxy_pass http://{{ .Name }};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
{{ end -}}
{{ end }}

server_names_hash_bucket_size 128;
EOF
        destination   = "local/load-balancer.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }
  }
}
