output "nomad_environment_variables" {
  description = "Nomad environment variables to configure the Nomad CLI"
  value       = <<-EOF
export NOMAD_ADDR=https://${local.dns.nomad}.${var.dns_hosted_zone_name}:4646
export NOMAD_CACERT=$(pwd)/infrastructure/nomad/tls/${local.dns.nomad}.${var.dns_hosted_zone_name}-agent-ca.pem
export NOMAD_CLIENT_CERT=$(pwd)/infrastructure/nomad/tls/global-cli-${local.dns.nomad}.${var.dns_hosted_zone_name}.pem
export NOMAD_CLIENT_KEY=$(pwd)/infrastructure/nomad/tls/global-cli-${local.dns.nomad}.${var.dns_hosted_zone_name}-key.pem
EOF
}
