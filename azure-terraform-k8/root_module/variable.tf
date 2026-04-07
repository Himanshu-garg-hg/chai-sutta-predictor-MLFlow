variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
}

variable "acr_name" {
  description = "Name of the Container Registry"
  type        = string

}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 3
}

variable "vm_size" {
  description = "VM size for the nodes in the default node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "storage_account_name" {
  description = "storage_account_name"
  type        = string
}