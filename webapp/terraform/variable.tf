variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "k8s-rg"
}

variable "admin_username" {
  description = "Admin username for all VMs"
  type        = string
  default     = "k8sadmin"
}

variable "admin_password" {
  description = "Admin password for all VMs (12+ chars, upper, lower, number, symbol)"
  type        = string
  sensitive   = true
}

variable "vm_size_master" {
  description = "VM size for master node"
  type        = string
  default     = "Standard_B2s"
}

variable "vm_size_worker" {
  description = "VM size for worker nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "vnet_cidr" {
  description = "Virtual Network CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet CIDR block"
  type        = string
  default     = "10.0.1.0/24"
}