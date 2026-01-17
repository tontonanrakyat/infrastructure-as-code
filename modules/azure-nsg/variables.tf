variable "resource_group_name" {
  type        = string
  description = "Nama Resource Group tempat NSG akan dibuat"
}

variable "location" {
  type        = string
  description = "Region Azure (contoh: indonesiacentral)"
}

variable "subnet_name" {
  type        = string
  description = "Nama subnet yang akan digunakan sebagai prefix nama NSG"
}

variable "subnet_id" {
  type        = string
  description = "ID spesifik dari subnet untuk proses NSG Association"
}

variable "tags" {
  type        = map(string)
  description = "Metadata tags untuk resource tracking"
  default     = {}
}