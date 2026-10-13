variable "name" {
  type        = string
  description = "Base name for the MongoDB instances."
}

variable "replica_count" {
  type        = number
  default     = 3
  description = "Number of MongoDB instances to create. Three is the minimum for a healthy replica set."
}

variable "zone" {
  type        = string
  description = "GCP zone to deploy the instances into."
}

variable "disk_size_gb" {
  type        = number
  default     = 100
  description = "Boot disk size in GB."
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Labels to apply to all instances."
}
