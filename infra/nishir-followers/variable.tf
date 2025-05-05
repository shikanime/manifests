variable "nodes" {
  type = map(object({
    node_ip = string
  }))
  description = "List of nodes with their IP addresses"
}

variable "rke2" {
  type = object({
    node_token = string
    server     = string
  })
  description = "K3s cluster join token"
  sensitive   = true
}
