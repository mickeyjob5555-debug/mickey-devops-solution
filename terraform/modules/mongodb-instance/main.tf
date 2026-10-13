resource "google_compute_instance" "mongodb" {
  count        = var.replica_count
  name         = "${var.name}-${count.index + 1}"
  machine_type = "n1-standard-1"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = var.disk_size_gb
    }
  }

  network_interface {
    network = "default"
    # access_config {} gives the instance a public IP. Left out on purpose.
    # A database should not be reachable from the internet.
  }

  labels = merge({
    database = "mongodb"
  }, var.labels)
}
