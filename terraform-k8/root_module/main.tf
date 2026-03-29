module "k8s_cluster" {
  source               = "../child_module"
  resource_group_name  = var.resource_group_name
  location             = var.location
  aks_cluster_name     = var.aks_cluster_name
  dns_prefix           = var.dns_prefix
  node_count           = var.node_count
  vm_size              = var.vm_size
  acr_name             = var.acr_name
  storage_account_name = var.storage_account_name
}