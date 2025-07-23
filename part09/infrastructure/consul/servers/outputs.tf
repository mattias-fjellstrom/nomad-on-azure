output "consul_environment_variables" {
  description = "Consul environment variables to configure the Consul CLI"
  value       = <<-EOF
export CONSUL_HTTP_ADDR=https://consul.${var.dns_hosted_zone_name}:443
export CONSUL_CACERT=$(pwd)/infrastructure/consul/tls/consul-agent-ca.pem
export CONSUL_CLIENT_CERT=$(pwd)/infrastructure/consul/tls/dc1-cli-consul-0.pem
export CONSUL_CLIENT_KEY=$(pwd)/infrastructure/consul/tls/dc1-cli-consul-0-key.pem
EOF
}
