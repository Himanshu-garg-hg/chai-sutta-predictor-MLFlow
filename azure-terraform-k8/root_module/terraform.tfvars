resource_group_name  = "k8_modal_rg"
location             = "East US"
aks_cluster_name     = "k8_modal_aks"
dns_prefix           = "k8modalaks"
node_count           = 1
vm_size              = "Standard_D2s_v3"
acr_name             = "modalacr"
storage_account_name = "modalstorageacc"