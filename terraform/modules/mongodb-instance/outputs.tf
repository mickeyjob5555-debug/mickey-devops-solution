output "instance_names" {
  description = "Names of the provisioned MongoDB instances."
  value       = google_compute_instance.mongodb[*].name
}

output "internal_ips" {
  description = "Internal IP addresses of the provisioned MongoDB instances."
  value       = google_compute_instance.mongodb[*].network_interface[0].network_ip
}
