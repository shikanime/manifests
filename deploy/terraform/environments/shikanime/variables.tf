variable "name" {
  type        = string
  description = "Name of the tenant"
  default     = "shikanime"
}

variable "project" {
  type        = string
  description = "Project ID"
  default     = "shikanime-studio"
}

variable "region" {
  type        = string
  description = "Deployment region"
  default     = "us-east1"
}

variable "zone" {
  type        = string
  description = "Deployment zone"
  default     = "us-east1-b"
}
