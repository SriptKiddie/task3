provider "google" {
  alias = "site02"
  # Configuration options
  region = "asia-southeast1"
  zone = "asia-southeast1-a"
  project = "terraformarmageddon"
  credentials = "terraformarmageddon-567cdc80ee62.json"
}

resource "google_compute_network" "asia_network" {
  name = "asia-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "asia_subnetwork" {
  name = "asia-subnetwork"
  ip_cidr_range = "192.168.0.0/24"
  network = google_compute_network.asia_network.id
}

resource "google_compute_instance" "asia_instance" {
  name = "vm01"
  machine_type = "e2-medium"
  zone = "asia-southeast1-a"
  boot_disk {
    initialize_params {
      image = "windows server-2019"
    }
  }
  network_interface {
    network = google_compute_network.asia_network.self_link
    subnetwork = google_compute_subnetwork.asia_subnetwork.self_link
  }
  
}

resource "google_compute_firewall" "asia_firewall" {
  name = "asia-firewall"
  network = google_compute_network.asia_network.self_link

  allow {
    protocol = "tcp"
    ports = ["3389"]
  }

  source_ranges = [google_compute_subnetwork.europe_subnetwork.ip_cidr_range]
}

resource "google_compute_address" "site02_gateway_ip" {
  name = "site02-gateway-ip"
  region = "asia-southeast1"  
}

resource "google_compute_vpn_gateway" "site02_gateway" {
  name = "site02-gateway"
  network = google_compute_network.asia_network.id
  region = "asia-southeast1"
  }  

resource "google_compute_vpn_tunnel" "site02_tunnel" {
  name = "site02-tunnel"
  region = "asia-east1"
  target_vpn_gateway = google_compute_vpn_gateway.site02_gateway.id
  shared_secret = var.shared_secret
  peer_ip = google_compute_address.hq_gateway_ip.address
}
