provider "google" {
  alias = "site01"
  # Configuration options
  region = "us-central1"
  zone = "us-central1-a"
  project = "terraformarmageddon"
  credentials = "terraformarmageddon-567cdc80ee62.json"
}

resource "google_compute_network" "americas_network" {
  name = "americas-network"
  auto_create_subnetworks = false
  mtu = 1460
}

resource "google_compute_subnetwork" "americas_subnetwork1" {
  name = "americas-subnetwork1"
  ip_cidr_range = "172.16.0.0/24"
  network = google_compute_network.americas_network.id
  private_ip_google_access = true
}

resource "google_compute_instance" "americas_instance_01" {
  name = "vm01"
  zone = "us-central1-a"
  machine_type = "e2-medium"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
    mode = "READ_WRITE"
  }
  network_interface {
    network = google_compute_network.americas_network.id
    subnetwork = google_compute_subnetwork.americas_subnetwork1.id
  }
}

resource "google_compute_subnetwork" "americas_subnetwork2" {
  name          = "americas-subnetwork2"
  ip_cidr_range = "172.16.0.0/24"
  network       = google_compute_network.americas_network.self_link
  region        = "southamerica-east1"
  private_ip_google_access = true
}

resource "google_compute_instance" "americas_instance_02" {
  name = "vm02"
  zone = "southamerica-east1-a"
  machine_type = "e2-medium"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
    mode = "READ_WRITE"
  }
  network_interface {
    network = google_compute_network.americas_network.id
    subnetwork = google_compute_subnetwork.americas_subnetwork2.id
  }
}

resource "google_compute_firewall" "americas_firewall" {
  name    = "americas-firewall"
  network = google_compute_network.americas_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = [google_compute_subnetwork.europe_subnetwork.ip_cidr_range]
}

resource "google_compute_firewall" "americas_to_europe_firewall" {
  name = "americas-to-europe-firewall"
  network = google_compute_network.americas_network.id
  
  allow {
      protocol = "tcp"
      ports    = ["22"]
    }
  source_ranges = ["0.0.0.0/0", google_compute_subnetwork.europe_subnetwork.ip_cidr_range]
  }

resource "google_compute_network_peering" "americas_to_europe_peering" {
  name = "americas-to-europe-peering"
  network = google_compute_network.americas_network.id
  peer_network = google_compute_network.europe_network.id
}