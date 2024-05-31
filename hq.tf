terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.29.0"
    }
  }
}

provider "google" {
  # Configuration options
  region = "europe-west1"
  zone = "europe-west1-b"
  project = "terraformarmageddon"
  credentials = "terraformarmageddon-567cdc80ee62.json"
}

resource "google_compute_network" "europe_network" {
  name = "europe-network"
  auto_create_subnetworks = false
  mtu = 1460
}

resource "google_compute_subnetwork" "europe_subnetwork" {
  name = "europe-subnetwork"
  network = google_compute_network.europe_network.id
  ip_cidr_range = "10.0.0.0/24"
  region = "europe-west1"
  private_ip_google_access = true
}

resource "google_compute_firewall" "europe_firewall" {
  name    = "europe-firewall"
  network = google_compute_network.europe_network.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["172.16.0.0/24", "192.168.0.0/24"]
  target_tags = ["europe-http-server", "americas-http-server", "asia-rdp-server"]
}

resource "google_compute_instance" "europe_instance" {
  name         = "europe-instance"
  machine_type = "e2-medium"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

metadata = {
    startup-script = "#Thanks to Remo!\n#!/bin/bash\n# Update and install Apache2\necho \"Startup script initiated. . .\"\napt update\napt install -y apache2\n\n# Start and enable Apache2\nsystemctl start apache2\nsystemctl enable apache2\n\n# GCP Metadata server base URL and header\nMETADATA_URL=\"http://metadata.google.internal/computeMetadata/v1\"\nMETADATA_FLAVOR_HEADER=\"Metadata-Flavor: Google\"\n\n# Use curl to fetch instance metadata\nlocal_ipv4=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/instance/network-interfaces/0/ip\")\nzone=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/instance/zone\")\nproject_id=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/project/project-id\")\nnetwork_tags=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/instance/tags\")\n\n# Create a simple HTML page and include instance details\ncat <<EOF > /var/www/html/index.html\n<html><body>\n<h2>Welcome to your custom website.</h2>\n<h3>Created with a direct input startup script!</h3>\n<p><b>Instance Name:</b> $(hostname -f)</p>\n<p><b>Instance Private IP Address: </b> $local_ipv4</p>\n<p><b>Zone: </b> $zone</p>\n<p><b>Project ID:</b> $project_id</p>\n<p><b>Network Tags:</b> $network_tags</p>\n</body></html>\nEOF"
}

service_account {
  scopes = ["cloud-platform"]
}

  network_interface {
    network = google_compute_network.europe_network.id
    subnetwork = google_compute_subnetwork.europe_subnetwork.id
    }
tags = ["europe-http-server"]
}

resource "google_compute_network_peering" "europe_to_americas" {
  provider = google
  name = "europe-to-americas"
  network = google_compute_network.europe_network.id
  peer_network = google_compute_network.americas_network.id
  }

resource "google_compute_address" "hq_gateway_ip" {
  name = "hq-gateway-ip"
  region = "europe-west1"  
}

  resource "google_compute_vpn_gateway" "hq_gateway" {
    name = "hq-gateway"
    network = google_compute_network.europe_network.id
    region = "europe-west1"
  }

  resource "google_compute_vpn_tunnel" "hq_tunnel" {
    name = "hq-tunnel"
    region = "europe-west1"
    target_vpn_gateway = google_compute_vpn_gateway.hq_gateway.id
    shared_secret = var.shared_secret
    peer_ip = google_compute_address.site02_gateway_ip.address
  }

  variable "shared_secret" {
    description = "The shared secret for the VPN connection"
    type = string
    sensitive = true
  }
