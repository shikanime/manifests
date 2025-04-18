variable "rke2" {
  type = object({
    node_token = string
    server     = string
  })
  description = "K3s cluster join token"
  sensitive   = true
}
