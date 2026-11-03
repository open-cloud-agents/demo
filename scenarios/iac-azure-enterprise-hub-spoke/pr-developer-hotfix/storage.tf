resource "azurerm_storage_account" "core_storage" {
  # INJECTED DEFECT: Renaming storage_account_name triggers 'forces replacement' (destructive storage loss!)
  name                     = "stpricingprodeu2v2"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"

  min_tls_version                 = "TLS1_2"
  enable_https_traffic_only       = true
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
}
