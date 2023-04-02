#Input Project ID and Billing Account

variable "project_id" {
  type    = string
  sensitive = false
}

variable "billing_account" {
  type    = string
  sensitive = false
}

provider "google" {
  project = var.project_id
  region = "us-west1"
}

#Create GCP Project

resource "google_project" "project" {
  name = "orangenoise"
  project_id = var.project_id
  billing_account = var.billing_account
  auto_create_network = false
}

#Create VPC Networks

#Create Managment Network

resource "google_compute_network" "mgmtnet" {
  name = "orangenoise-managemnet-vpc"
  auto_create_subnetworks = false
  routing_mode = "GLOBAL"
  depends_on = [google_project.project]
}

#Create Development Network

resource "google_compute_network" "devnet" {
  name = "orangenoise-dev-vpc"
  auto_create_subnetworks = false
  routing_mode = "GLOBAL"
  depends_on = [google_project.project]
}

#Create Staging Network

resource "google_compute_network" "stagingnet" {
  name = "orangenoise-staging-vpc"
  auto_create_subnetworks = false
  routing_mode = "GLOBAL"
  depends_on = [google_project.project]
}

#Create Production Network

resource "google_compute_network" "prodnet" {
  name = "orangenoise-prod-vpc"
  auto_create_subnetworks = false
  routing_mode = "GLOBAL"
  depends_on = [google_project.project]
}

#Create Management Subnet

resource "google_compute_subnetwork" "mgmtsubnet" {
  name = "mgmt-subnet-us-west1"
  network = google_compute_network.mgmtnet.id
  ip_cidr_range = "10.1.0.0/22"
  region = "us-west1"
  depends_on = [google_compute_network.mgmtnet]
}

#Create Development Subnet

resource "google_compute_subnetwork" "devsubnet" {
  name = "dev-subnet-us-west1"
  network = google_compute_network.devnet.id
  ip_cidr_range = "10.1.4.0/22"
  region = "us-west1"
  depends_on = [google_compute_network.mgmtnet]
}

#Create Staging Subnet

resource "google_compute_subnetwork" "stagesubnet" {
  name = "staging-subnet-us-west1"
  network = google_compute_network.stagingnet.id
  ip_cidr_range = "10.1.8.0/22"
  region = "us-west1"
  depends_on = [google_compute_network.mgmtnet]
}

#Create Production Subnet

resource "google_compute_subnetwork" "prodsubnet" {
  name = "prod-subnet-us-west1"
  network = google_compute_network.prodnet.id
  ip_cidr_range = "10.1.12.0/22"
  region = "us-west1"
  depends_on = [google_compute_network.mgmtnet]
}

#Create Peering orangenoise-managemnet-vpc to orangenoise-dev-vpc

resource "google_compute_network_peering" "managment_dev_network_peering" {
  name          = "management-dev-peering"
  network       = google_compute_network.mgmtnet.id
  peer_network  = google_compute_network.devnet.id
  export_custom_routes = true
  import_custom_routes = true
}

resource "google_compute_network_peering" "dev_management_network_peering" {
  name          = "dev-management-peering"
  network       = google_compute_network.devnet.id
  peer_network  = google_compute_network.mgmtnet.id
  export_custom_routes = true
  import_custom_routes = true
}

#Create Peering orangenoise-managemnet-vpc to orangenoise-staging-vpc

resource "google_compute_network_peering" "managment_staging_network_peering" {
  name          = "management-staging-peering"
  network       = google_compute_network.mgmtnet.id
  peer_network  = google_compute_network.stagingnet.id
  export_custom_routes = true
  import_custom_routes = true
}

resource "google_compute_network_peering" "staging_management_network_peering" {
  name          = "staging-management-peering"
  network       = google_compute_network.stagingnet.id
  peer_network  = google_compute_network.mgmtnet.id
  export_custom_routes = true
  import_custom_routes = true
}

#Create Peering orangenoise-managemnet-vpc to orangenoise-prod-vpc

resource "google_compute_network_peering" "managment_prod_network_peering" {
  name          = "management-prod-peering"
  network       = google_compute_network.mgmtnet.id
  peer_network  = google_compute_network.prodnet.id
  export_custom_routes = true
  import_custom_routes = true
}

resource "google_compute_network_peering" "prod_management_network_peering" {
  name          = "prod-management-peering"
  network       = google_compute_network.prodnet.id
  peer_network  = google_compute_network.mgmtnet.id
  export_custom_routes = true
  import_custom_routes = true
}

#Create Cloud Router

resource "google_compute_router" "router" {
  name = "cloud-router-us-west1"
  region = google_compute_subnetwork.mgmtsubnet.region
  network = google_compute_network.mgmtnet.id
  depends_on = [google_compute_subnetwork.mgmtsubnet]
  bgp {
    asn = 64514
  }
}

#Create Cloud NAT Gateway

resource "google_compute_router_nat" "nat" {
  name = "nat-gateway-us-west1"
  router = google_compute_router.router.name
  region = google_compute_router.router.region
  nat_ip_allocate_option = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  depends_on = [google_compute_router.router]

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

#Egress Firewall Rule for all Networks

resource "google_compute_firewall" "egress-allow-all-management-vpc" {
  name = "management-vpc-egress-allow-all"
  network = google_compute_network.mgmtnet.id
  direction = "EGRESS"
  priority = 1000
  depends_on = [google_compute_router.router]

  # Allow all traffic
  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "egress-allow-all-dev-vpc" {
  name = "dev-vpc-egress-allow-all"
  network = google_compute_network.devnet.id
  direction = "EGRESS"
  priority = 1000
  depends_on = [google_compute_router.router]

  # Allow all traffic
  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "egress-allow-all-staging-vpc" {
  name = "staging-vpc-egress-allow-all"
  network = google_compute_network.stagingnet.id
  direction = "EGRESS"
  priority = 1000
  depends_on = [google_compute_router.router]

  # Allow all traffic
  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "egress-allow-all-prod-vpc" {
  name = "prod-vpc-egress-allow-all"
  network = google_compute_network.prodnet.id
  direction = "EGRESS"
  priority = 1000
  depends_on = [google_compute_router.router]

  # Allow all traffic
  allow {
    protocol = "all"
  }
}

#Internal Firewall Rules for Segmented Traffic
#Management-VPC

resource "google_compute_firewall" "internal-allow-management-vpc" {
  name = "managmenet-vpc-internal-allow"
  network = google_compute_network.mgmtnet.id
  direction = "INGRESS"
  priority = 1000
  depends_on = [google_compute_router.router]

  # Allow all traffic from all VPCs
  source_ranges = ["10.1.0.0/22", "10.1.4.0/22", "10.1.8.0/22", "10.1.12.0/22"]

  allow {
    protocol = "all"
  }
}

#Development-VPC

resource "google_compute_firewall" "internal-allow-dev-vpc" {
  name = "dev-vpc-internal-allow"
  network = google_compute_network.devnet.id
  direction = "INGRESS"
  priority = 1000
  depends_on = [google_compute_router.router]

  # Allow all traffic from all VPCs
  source_ranges = ["10.1.0.0/22", "10.1.4.0/22"]

  allow {
    protocol = "all"
  }
}

#Staging-VPC

resource "google_compute_firewall" "internal-allow-staging-vpc" {
  name = "staging-vpc-internal-allow"
  network = google_compute_network.stagingnet.id
  direction = "INGRESS"
  priority = 1000
  depends_on = [google_compute_router.router]

  # Allow all traffic from all VPCs
  source_ranges = ["10.1.0.0/22", "10.1.8.0/22"]

  allow {
    protocol = "all"
  }
}

#Production-VPC

resource "google_compute_firewall" "internal-allow-prod-vpc" {
  name = "prod-vpc-internal-allow"
  network = google_compute_network.prodnet.id
  direction = "INGRESS"
  priority = 1000
  depends_on = [google_compute_router.router]

  # Allow all traffic from all VPCs
  source_ranges = ["10.1.0.0/22", "10.1.12.0/22"]

  allow {
    protocol = "all"
  }
}

#RDP Firewall Rule

resource "google_compute_firewall" "ingress-allow-rdp-management-vpc" {
  name = "management-vpc-ingress-allow-rdp"
  network = google_compute_network.mgmtnet.id
  direction = "INGRESS"
  priority = 1000
  target_tags = ["allow-rdp"]
  depends_on = [google_compute_router.router]

  # Allow ingress traffic on TCP port 3389 from IP address 73.59.83.115
  source_ranges = ["73.59.83.115"]
  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }
}

#Create Static Public IP Address for JumpHost

resource "google_compute_address" "static_ip" {
  name = "windows-instance-ip"
  depends_on = [google_compute_router.router]
}

#Create Jump Host Compute Instance

resource "google_compute_instance" "windows_instance_1" {
  name         = "on-jh01"
  machine_type = "n1-standard-2"
  zone         = "us-west1-b"

  boot_disk {
    initialize_params {
      image = "windows-cloud/windows-2022"
      size = "128"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.mgmtsubnet.id

    access_config {
      nat_ip = google_compute_address.static_ip.address
    }
  }

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  tags = ["allow-rdp"]
}

#Create Active Directory Host

resource "google_compute_instance" "windows_instance_2" {
  name         = "on-ad01"
  machine_type = "n1-standard-2"
  zone         = "us-west1-b"

  boot_disk {
    initialize_params {
      image = "windows-cloud/windows-2022"
      size = "128"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.mgmtsubnet.id
  }

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}
