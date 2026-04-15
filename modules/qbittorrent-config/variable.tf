variable "annotations" {
  type        = map(string)
  description = "Annotations forwarded from Terraform values/annotations"
  default     = {}
}

variable "labels" {
  type        = map(string)
  description = "Labels forwarded from Terraform values/labels"
  default     = {}
}

variable "name" {
  type        = string
  description = "Base application name used for generated resource names"
  default     = "qbittorrent"
}

variable "namespace" {
  type        = string
  description = "Namespace where generated resources are created"
  default     = "shikanime"
}

variable "url" {
  type        = string
  description = "qBittorrent base URL used by automation scripts"
  default     = "https://qbittorrent"
}

variable "username" {
  type        = string
  description = "qBittorrent username used by automation scripts"
  default     = "admin"
}

variable "password" {
  type        = string
  description = "qBittorrent password used by automation scripts; when null, a random password is generated"
  default     = null
}
