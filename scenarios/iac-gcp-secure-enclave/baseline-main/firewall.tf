resource "google_compute_firewall" "allow_internal_enclave" {
  name    = "fw-enclave-allow-internal"
  network = google_compute_network.enclave_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["5432", "8080", "443"]
  }

  source_ranges = ["10.10.0.0/20", "10.20.0.0/16"]
}

