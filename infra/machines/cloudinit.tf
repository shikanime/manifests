locals {
  cloudinit_config = {
    users = [
      "shika"
    ]
    package_update = true
    packages = [
      "curl",
      "networkd-dispatcher"
    ]
    write_files = [
      {
        path        = "/etc/sysctl.d/99-k3s.conf"
        content     = <<-EOT
          fs.inotify.max_user_watches = 524288
          fs.inotify.max_user_instances = 8192
          fs.inotify.max_queued_events = 16384
          fs.file-max = 131072
          user.max_inotify_instances = 8192
          user.max_inotify_watches = 524288
        EOT
        owner       = "root:root"
        permissions = "0644"
      },
      {
        path        = "/etc/sysctl.d/99-tailscale.conf"
        content     = <<-EOT
          net.ipv4.ip_forward = 1
          net.ipv6.conf.all.forwarding = 1
        EOT
        owner       = "root:root"
        permissions = "0644"
      },
      {
        path    = "/etc/networkd-dispatcher/routable.d/50-tailscale"
        content = <<-EOT
          #!/bin/sh

          ethtool -K wlan0 rx-udp-gro-forwarding on rx-gro-list off
        EOT
      }
    ]
  }
  nishir_cloudinit_config = merge(
    local.cloudinit_config,
    {
      runcmd = [
        "sudo systemctl enable --now media-shika-Remilia.automount",
        "curl -fsSL https://get.k3s.io | sh",
        "curl -fsSL https://tailscale.com/install.sh | sh",
      ]
      write_files = concat(
        [
          {
            path = "/etc/rancher/k3s/k3s.yaml"
            content = jsonencode({
              server = "https://${var.devices.nishir}:6443/"
              vpn-auth = join(", ", [
                "name=tailscale",
                "joinKey=${tailscale_tailnet_key.nishir.key}",
                "extraArgs=--ssh --advertise-exit-node --accept-routes"
              ])
              tls-san            = [var.devices.fushi, "fushi.local"]
              data-dir           = "/media/shika/flandre/rancher/k3s"
              etcd-s3            = true
              etcd-s3-access-key = scaleway_iam_api_key.fushi.access_key
              etcd-s3-secret-key = scaleway_iam_api_key.fushi.secret_key
              etcd-s3-endpoint   = "s3.fr-par.scw.cloud"
              etcd-s3-region     = data.scaleway_object_bucket.etcd_backups.region
              etcd-s3-bucket     = data.scaleway_object_bucket.etcd_backups.name
            })
            owner       = "root:root"
            permissions = "0600"
          },
          {
            path        = "/etc/systemd/system/media-shika-remilia.mount"
            content     = <<-EOT
              [Unit]
              Description=Mount Remilia disk

              [Mount]
              What=/dev/disk/by-label/remilia
              Where=/media/shika/remilia
              Type=ext4
              Options=defaults

              [Install]
              WantedBy=multi-user.target
            EOT
            owner       = "root:root"
            permissions = "0644"
          },
          {
            path        = "/etc/systemd/system/media-shika-remilia.automount"
            content     = <<-EOT
              [Unit]
              Description=Automount Remilia disk

              [Automount]
              Where=/media/shika/remilia

              [Install]
              WantedBy=multi-user.target
            EOT
            owner       = "root:root"
            permissions = "0644"
          },
        ],
        local.cloudinit_config.write_files
      )
    }
  )
  fushi_cloudinit_config = merge(
    local.cloudinit_config,
    {
      runcmd = [
        "sudo systemctl enable --now media-shika-flandre.automount",
        "curl -fsSL https://get.k3s.io | sh -s - --token \"`ssh shika@${var.devices.nishir} sudo cat /var/lib/rancher/k3s/server/token`\"",
        "curl -fsSL https://tailscale.com/install.sh | sh",
      ]
      write_files = concat(
        [
          {
            path = "/etc/rancher/k3s/k3s.yaml"
            content = jsonencode({
              vpn-auth           = <<EOT
                name=tailscale,
                joinKey=${tailscale_tailnet_key.fushi.key},
                extraArgs=--ssh --advertise-exit-node --accept-routes
              EOT
              token              = data.scaleway_secret_version.nishir_k3s_node_token.data
              tls-san            = [var.devices.nishir, "nishir.local"]
              data-dir           = "/media/shika/remilia/rancher/k3s"
              etcd-s3            = true
              etcd-s3-access-key = scaleway_iam_api_key.fushi.access_key
              etcd-s3-secret-key = scaleway_iam_api_key.fushi.secret_key
              etcd-s3-endpoint   = "s3.fr-par.scw.cloud"
              etcd-s3-region     = data.scaleway_object_bucket.etcd_backups.region
              etcd-s3-bucket     = data.scaleway_object_bucket.etcd_backups.name
            })
            owner       = "root:root"
            permissions = "0600"
          },
          {
            path        = "/etc/systemd/system/media-shika-flandre.mount"
            content     = <<-EOT
              [Unit]
              Description=Mount Flandre disk

              [Mount]
              What=/dev/disk/by-label/flandre
              Where=/media/shika/flandre
              Type=ext4
              Options=defaults

              [Install]
              WantedBy=multi-user.target
            EOT
            owner       = "root:root"
            permissions = "0644"
          },
          {
            path        = "/etc/systemd/system/media-shika-flandre.automount"
            content     = <<-EOT
              [Unit]
              Description=Automount Flandre disk

              [Automount]
              Where=/media/shika/flandre

              [Install]
              WantedBy=multi-user.target
            EOT
            owner       = "root:root"
            permissions = "0644"
          }
        ],
        local.cloudinit_config.write_files
      )
    }
  )
}

data "cloudinit_config" "nishir" {
  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content      = <<-EOT
      #cloud-config
      ${jsonencode(local.nishir_cloudinit_config)}
    EOT
  }
}

resource "null_resource" "nishir" {
  connection {
    user = "shika"
    host = var.devices.nishir
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install cloud-init",
      "sudo cloud-init init --local",
    ]
  }
  provisioner "file" {
    content     = data.cloudinit_config.nishir.rendered
    destination = "/var/lib/cloud/instance/cloud-config.txt"
  }
}

data "cloudinit_config" "fushi" {
  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"

    content = <<-EOT
      #cloud-config
      ${jsonencode(local.fushi_cloudinit_config)}
    EOT
  }
}

resource "null_resource" "fushi" {
  connection {
    user = "shika"
    host = "fushi.local"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install cloud-init",
      "sudo cloud-init init --local",
    ]
  }
  provisioner "file" {
    content     = data.cloudinit_config.fushi.rendered
    destination = "/var/lib/cloud/instance/cloud-config.txt"
  }
}
