output "region" {
  value       = var.region
  description = "GCloud Region"
}

output "project_id" {
  value       = var.project_id
  description = "GCloud Project ID"
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.tpu_cluster.name
  description = "GKE Cluster Name"
}


output "filestore_ip" {
  value       = google_filestore_instance.instance.networks[0].ip_addresses[0]
  description = "whether we want to make TPU node private"
}