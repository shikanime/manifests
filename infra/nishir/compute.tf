module "container_vm" {
  source  = "terraform-google-modules/container-vm/google"
  version = "~> 3.2"

  container = {
    image = "tailscale/tailscale"
    env = [
      {
        name  = "TS_AUTHKEY"
        value = local.tailscale_node_singapore_token.auth_key
      }
    ],

    volumeMounts = [
      {
        mountPath = "/var/lib"
        name      = "var-lib"
        readOnly  = false
      },
      {
        mountPath = "/dev/net/tun"
        name      = "tun-device"
        readOnly  = false
      }
    ]

    securityContext = {
      capabilities = {
        add = ["NET_ADMIN", "NET_RAW"]
      }
    }
  }
  volumes = [
    {
      name = "var-lib"
      hostPath = {
        path = "/var/lib"
      }
    },
    {
      name = "tun-device"
      hostPath = {
        path = "/dev/net/tun"
      }
    }
  ]
  restart_policy = "Always"
}

module "network" {
  source  = "terraform-google-modules/network/google"
  version = "~> 10.0"

  project_id   = var.project
  network_name = var.name
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name   = var.name
      subnet_ip     = "10.125.0.0/20"
      subnet_region = "asia-northeast1"
    }
  ]
}

module "cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 6.2"

  project = var.project
  name    = var.name
  region  = "asia-northeast1"
  network = module.network.network_self_link
  nats = [
    { name = var.name }
  ]
}

module "service_accounts" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "~> 4.4"
  project_id = var.project
  prefix     = var.name
  names      = ["edge"]
}

module "instance_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "~> 13.0"

  project_id           = var.project
  region               = "asia-northeast1"
  network              = module.network.network_self_link
  subnetwork           = module.network.subnets_self_links.0
  name_prefix           = var.name
  enable_shielded_vm   = true
  machine_type         = "e2-micro"
  source_image_project = regex("https://www.googleapis.com/compute/v1/projects/(.+)/global/images/.+", module.container_vm.source_image).0
  source_image         = regex("https://www.googleapis.com/compute/v1/projects/.+/global/images/(.+)", module.container_vm.source_image).0
  service_account = {
    email  = module.service_accounts.email
    scopes = []
  }
  metadata = {
    "${module.container_vm.metadata_key}" = module.container_vm.metadata_value
  }
  labels = {
    "container-vm" = module.container_vm.vm_container_label
  }
}

module "mig" {
  source  = "terraform-google-modules/vm/google//modules/mig"
  version = "~> 13.0"

  project_id        = var.project
  instance_template = module.instance_template.self_link
  region            = "asia-northeast1"
  hostname          = var.name
  target_size       = 1
}