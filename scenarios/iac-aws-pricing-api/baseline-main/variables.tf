variable "name_suffix" {
  type        = string
  description = "Suffix on every resource name, so more than one copy of this estate can live in the account"

  validation {
    condition     = can(regex("^[a-z0-9]{1,12}$", var.name_suffix))
    error_message = "name_suffix must be 1-12 lowercase letters or digits."
  }
}

variable "access_logs_bucket" {
  type = string
}

variable "permissions_boundary_arn" {
  type        = string
  description = "The account's permissions boundary, attached to every IAM role"
}

variable "db_instance_class" {
  default = "db.t4g.micro"
}

variable "db_allocated_storage" {
  default = 20
}
