resource "google_compute_network" "default" {
  project = var.project
  name    = var.name
}

resource "google_compute_address" "default" {
  name = var.name
}

resource "google_compute_instance" "default" {
  name         = var.name
  machine_type = "e2-micro"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network = google_compute_network.default.name
    access_config {
      nat_ip = google_compute_address.default.address
    }
  }
}
