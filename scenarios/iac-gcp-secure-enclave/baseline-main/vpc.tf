resource "google_compute_network" "enclave_vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "enclave_subnet" {
  name                     = "sb-enclave-${var.region}"
  ip_cidr_range            = "10.10.0.0/20"
  region                   = var.region
  network                  = google_compute_network.enclave_vpc.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = "10.20.0.0/16"
  }

  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = "10.30.0.0/20"
  }
}

resource "google_compute_router" "enclave_router" {
  name    = "cr-enclave-${var.region}"
  region  = var.region
  network = google_compute_network.enclave_vpc.id
}

resource "google_compute_router_nat" "enclave_nat" {
  name                               = "nat-enclave-${var.region}"
  router                             = google_compute_router.enclave_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
