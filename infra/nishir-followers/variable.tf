variable "k3s" {
  type = object({
    token  = string
    server = string
  })
  description = "K3s cluster join token"
  sensitive   = true
}
