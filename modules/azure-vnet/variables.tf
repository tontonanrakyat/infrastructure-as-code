variable "resource_group_name" {
  type        = string
  description = "Nama RG dari modul sebelumnya"
}

variable "location" {
  type        = string
  description = "Region Azure (indonesiacentral)"
}

variable "vnet_address_space" {
  type        = list(string)
  default     = ["172.22.0.0/16"]
}

variable "subnets" {
  type = map(object({
    address_prefixes = list(string)
  }))
  description = "Mapping Subnet berdasarkan Manifesto T0-T9"
}