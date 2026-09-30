variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type    = string
  default = "week-10-epicbook-rg"
}

variable "admin_user" {
  type    = string
  default = "azureuser"
}

variable "ssh_allowed_cidr" {
  description = "Public IPv4 CIDR of the machine running the App Pipeline"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.ssh_allowed_cidr))
    error_message = "Use a valid CIDR, for example 51.8.104.41/32."
  }
}

variable "ssh_public_key" {
  description = "Public half of the SSH key used by the App Pipeline"
  type        = string
}

variable "mysql_server_name" {
  description = "Globally unique lowercase MySQL server name"
  type        = string
  default     = "epicbook-michael-c3-2026"
}

variable "mysql_admin_password" {
  description = "MySQL administrator password, supplied as a secret pipeline variable"
  type        = string
  sensitive   = true
}
