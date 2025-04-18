variable "rke2" {
  type = object({
    token  = string
    server = string
  })
  description = "K3s cluster join token"
  sensitive   = true
}
