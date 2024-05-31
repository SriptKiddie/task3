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
/*
resource "google_compute_vpn_tunnel" "europe_vpn" {
  name                  = "europe-vpn"
  peer_ip               = "x.x.x.x"  # Replace with the IP address of the VPN peer in Europe
  shared_secret         = "your_shared_secret"  # Replace with your shared secret for the VPN connection

  shared_secret_hash    = base64encode("your_shared_secret")  # Optional: Hashed version of the shared secret

  local_traffic_selector = ["0.0.0.0/0"]  # Allow all traffic from your network to go through the VPN tunnel
  remote_traffic_selector = ["0.0.0.0/0"]  # Allow all traffic from the remote network to go through the VPN tunnel

  target_vpn_gateway    = google_compute_vpn_gateway.europe_vpn_gateway.self_link
  target_vpn_gateway_interface = 0  # Index of the interface on the target VPN gateway

  local_ip_address      = "x.x.x.x"  # Replace with the local IP address for the VPN tunnel
  local_network_interface = "interface_name"  # Replace with the name of the local network interface

  remote_ip_ranges      = ["x.x.x.x/32"]  # Replace with the IP range of the remote network in Europe
  }
}*/

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
