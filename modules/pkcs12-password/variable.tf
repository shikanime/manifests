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
  description = "Secret name to create"
}

variable "namespace" {
  type        = string
  description = "Namespace where generated resources are created"
  default     = "shikanime"
}
