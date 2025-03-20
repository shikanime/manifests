variable "name" {
  type        = string
  description = "Name of the cluster"
  default     = "nishir"
}

variable "endpoints" {
  type = object({
    nishir = string
  })
  description = "Nodes DNS name"
  default = {
    nishir = "nishir.taila659a.ts.net"
  }
}

variable "tailscale_operator" {
  type = object({
    client_id     = string
    client_secret = string
  })
  description = "Tailscale operator authentication credentials"
  sensitive   = true
}
