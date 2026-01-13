variable "resource_group_name" {
  description = "Nama Resource Group"
  type        = string
}

variable "location" {
  description = "Region Azure"
  type        = string
  default     = "indonesiacentral"
}

variable "tags" {
  description = "Tagging untuk resource"
  type        = map(string)
  default     = {}
}