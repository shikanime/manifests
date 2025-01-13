locals {
  k3s_server_install_script = [
    join(" ", [
      "curl -fsSL https://get.k3s.io | sh -s -",
      "--cluster-cidrs ${join(",", var.cirds.cluster)}",
      "--etcd-s3-access-key ${local.etcd_snapshot_s3_creds.access_key_id}",
      "--etcd-s3-bucket ${var.buckets.etcd_backups}",
      "--etcd-s3-endpoint ${var.endpoints.s3}",
      "--etcd-s3-region ${var.regions.aws_s3_bucket}",
      "--etcd-s3-secret-key ${local.etcd_snapshot_s3_creds.secret_access_key}",
      "--etcd-s3",
      "--flannel-backend host-gw",
      "--node-ip ${join(",", var.ip_addresses.nishir)}",
      "--service-cidrs ${join(",", var.cirds.service)}",
      "--tls-san ${var.endpoints.nishir}",
    ])
  ]
  k3s_agent_install_script = [
    join(" ", [
      "curl -fsSL https://get.k3s.io | sh -s -",
      "--cluster-cidr ${join(",", var.cirds.cluster)}",
      "--flannel-backend host-gw",
      "--node-ip ${join(",", var.ip_addresses.flandre)}",
      "--server https://${var.endpoints.nishir}:6443",
      "--service-cidr ${join(",", var.cirds.service)}",
      "--tls-san ${var.endpoints.flandre}",
      "--token ${local.tokens.k3s_server_token}",
    ])
  ]
  tailscale_install_script = [
    "curl -fsSL https://tailscale.com/install.sh | sh",
    join(" ", [
      "tailscale",
      "up",
      "--accept-routes",
      "--advertise-exit-node",
      "--authkey ${local.tokens.tailscale_auth_key}",
      "--ssh"
    ])
  ]
  sysctl_config = join("\n", [
    "kernel.panic=10",
    "kernel.panic_on_oops=1",
    "fs.inotify.max_user_watches=524288",
    "fs.inotify.max_user_instances=8192",
    "fs.inotify.max_queued_events=16384",
    "fs.file-max=131072",
    "net.core.rmem_default=7340032",
    "user.max_inotify_instances=8192",
    "user.max_inotify_watches=524288",
    "vm.overcommit_memory=1"
  ])
  tailscale_sysctl_config = join("\n", [
    "net.ipv4.ip_forward=1",
    "net.ipv6.conf.all.forwarding=1"
  ])
}

resource "terraform_data" "nishir" {
  input = {
    tailscale_install_script  = local.tailscale_install_script
    k3s_server_install_script = local.k3s_server_install_script
  }
  connection {
    type     = local.connection_creds.nishir_type
    user     = local.connection_creds.nishir_user
    host     = local.connection_creds.nishir_host
    password = local.connection_creds.nishir_password
  }
  provisioner "file" {
    content     = local.tailscale_sysctl_config
    destination = "/etc/sysctl.d/99-tailscale.conf"
  }
  provisioner "file" {
    content     = local.sysctl_config
    destination = "/etc/sysctl.d/99-k8s.conf"
  }
  provisioner "remote-exec" {
    inline = self.tailscale_install_script
  }

  provisioner "remote-exec" {
    inline = self.k3s_server_install_script
  }
}

resource "terraform_data" "flandre" {
  input = {
    tailscale_install_script = local.tailscale_install_script
    k3s_agent_install_script = local.k3s_agent_install_script
  }
  connection {
    type     = local.connection_creds.flandre_type
    user     = local.connection_creds.flandre_user
    host     = local.connection_creds.flandre_host
    password = local.connection_creds.flandre_password
  }
  provisioner "file" {
    content     = local.tailscale_sysctl_config
    destination = "/etc/sysctl.d/99-tailscale.conf"
  }
  provisioner "file" {
    content     = local.sysctl_config
    destination = "/etc/sysctl.d/99-k8s.conf"
  }
  provisioner "remote-exec" {
    inline = self.tailscale_install_script
  }
  provisioner "remote-exec" {
    inline = self.k3s_agent_install_script
  }
}
