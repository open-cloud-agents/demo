variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "prod-secure-enclave"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "network_name" {
  description = "VPC network name"
  type        = string
  default     = "vpc-secure-enclave"
}
