variable "project" {
  type        = string
  description = "Project name"
  default     = "shikanime-studio-labs"
}

variable "name" {
  type        = string
  description = "Name of the cluster"
  default     = "kaltashar"
}

variable "display_name" {
  type        = string
  description = "Display name of the cluster"
  default     = "Kaltashar"
}

variable "repository" {
  type        = string
  description = "Repository name"
  default     = "infinity-blackhole/dags"
}
