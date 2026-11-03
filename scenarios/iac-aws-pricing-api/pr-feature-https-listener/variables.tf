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

variable "hosted_zone_id" {
  type        = string
  description = "Route 53 hosted-zone ID for the pricing API domain"

  validation {
    condition = (
      can(regex("^Z[A-Z0-9]+$", var.hosted_zone_id)) &&
      var.hosted_zone_id != "ZPLACEHOLDER00000000"
    )
    error_message = "hosted_zone_id must be the real createfuture.cloud Route 53 hosted-zone ID, not the documented placeholder."
  }
}

variable "api_domain_name" {
  type        = string
  description = "Public DNS name for the pricing API"
}

variable "db_instance_class" {
  default = "db.t4g.micro"
}

variable "db_allocated_storage" {
  default = 20
}
