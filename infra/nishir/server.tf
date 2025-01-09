resource "hcloud_server" "node1" {
  name        = "${var.name}-singapore"
  image       = "docker-ce"
  server_type = "cpx11"
  location    = "sin"
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  user_data = <<-EOT
  #cloud-config
  write_files:
    - path: /opt/nishir/compose.yaml
      permissions: 0644
      owner: root
      content: |
        services:
          tailscaled:
            image: tailscale/tailscale
            volumes:
              - /var/lib:/var/lib
              - /dev/net/tun:/dev/net/tun
            network_mode: host
            cap_add:
              - NET_ADMIN
              - NET_RAW
            environment:
              - TS_AUTHKEY=${local.tailscale_node_singapore_token.auth_key}
    - path: /etc/systemd/system/nishir.service
      permissions: 0644
      owner: root
      content: |
        [Unit]
        Description=Start Nishir node

        [Service]
        ExecStart=docker compose -f /opt/nishir/compose.yaml up
        ExecStop=docker compose -f /opt/nishir/compose.yaml stop
        ExecStopPost=docker compose -f /opt/nishir/compose.yaml down
    EOT
}