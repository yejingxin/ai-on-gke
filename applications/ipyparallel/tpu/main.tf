data "google_container_engine_versions" "gke_version" {
  location       = var.region
  version_prefix = "1.30."
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.resource_name_prefix}-net"
  auto_create_subnetworks = "true"
}


resource "google_container_cluster" "tpu_cluster" {
  name     = "${var.resource_name_prefix}-gke-cluster"
  location = var.region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  # remove_default_node_pool = true
  initial_node_count       = 1
  networking_mode          = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/14"
    services_ipv4_cidr_block = "/20"
  }
  default_max_pods_per_node = 15
  node_config {
    machine_type = var.cpu_machine_type
  }
  addons_config {
  gcp_filestore_csi_driver_config {
    enabled = true
  }
  }
  deletion_protection = false

  release_channel {
    channel = "UNSPECIFIED"
  }

  network            = google_compute_network.vpc.name
  subnetwork         = google_compute_network.vpc.name
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"


  timeouts {
    create = "120m"
    update = "120m"
  }
}

# Separately Managed Node Pool
resource "google_container_node_pool" "multihost_tpu" {
  name           = "${var.resource_name_prefix}-nodepool"
  provider       = google-beta
  project        = var.project_id
  location       = var.region
  node_locations = [var.tpu_node_pool.zone]
  cluster        = google_container_cluster.tpu_cluster.name

  initial_node_count = var.tpu_node_pool.node_count

  management {
    auto_upgrade = false
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    host_maintenance_policy {
      maintenance_interval = var.maintenance_interval
    }
    labels = {
      env = var.project_id
    }
    gvnic {
      enabled = true
    }
    gcfs_config {
      enabled = true
    }

    image_type   = "COS_CONTAINERD"
    machine_type = var.tpu_node_pool.machine_type
    tags         = ["gke-node"]
  }

  placement_policy {
    type         = "COMPACT"
    tpu_topology = var.tpu_node_pool.topology
  }
}

resource "google_filestore_instance" "instance" {
  name     = "${var.resource_name_prefix}-filestore"
  location = var.filestore.zone
  tier     = "BASIC_HDD"

  file_shares {
    capacity_gb = 1024
    name        = var.filestore.share_name
  }

  networks {
    network = google_compute_network.vpc.name
    modes   = ["MODE_IPV4"]
  }
}

resource "local_file" "preprov_filestore_yaml" {
  content  = templatefile("${path.module}/template/preprov-filestore.yaml", 
  { ip = google_filestore_instance.instance.networks[0].ip_addresses[0], share_name = var.filestore.share_name, instance_id = google_filestore_instance.instance.name, zone = var.filestore.zone })
  filename = "${path.module}/preprov-filestore.yaml"
}

resource "local_file" "deployment_yaml" {
  content = templatefile("${path.module}/template/deployment.yaml",
    {
      topology   = var.tpu_node_pool.topology,
      tpu_type   = var.tpu_type_map[var.tpu_node_pool.machine_type],
      image      = var.docker_image,
      node_count = var.tpu_node_pool.node_count,
    jupyter_token = var.jupyter_token,

  })
  filename = "${path.module}/deployment.yaml"
}

resource "local_file" "service_yaml" {
  content = templatefile("${path.module}/template/service.yaml", {})
  filename = "${path.module}/service.yaml"
}

resource "local_file" "run_bash" {
  content = templatefile("${path.module}/template/ipp_notebook.sh", 
  {
    cluster_name=google_container_cluster.tpu_cluster.name,
    region=var.region,
    project_id = var.project_id,
    jupyter_token = var.jupyter_token,
    ip = google_filestore_instance.instance.networks[0].ip_addresses[0],
    share_name = var.filestore.share_name,
  })
  filename = "${path.module}/ipp_notebook.sh"
}