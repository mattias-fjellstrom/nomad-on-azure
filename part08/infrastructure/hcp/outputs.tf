output "boundary_url" {
  description = "The URL of the Boundary cluster"
  value       = hcp_boundary_cluster.default.cluster_url
}
