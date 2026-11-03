resource "azurerm_private_dns_zone" "postgres_dns" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  name                  = "dns-link-hub"
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns.name
  virtual_network_id    = azurerm_virtual_network.hub_vnet.id
  resource_group_name   = azurerm_resource_group.rg.name
}

resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = "psql-enterprise-core"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  version                = "15"
  delegated_subnet_id    = azurerm_subnet.db_subnet.id
  private_dns_zone_id    = azurerm_private_dns_zone.postgres_dns.id
  administrator_login    = "psqladmin"
  administrator_password = "ComplexSecurePassword2026!" # pragma: allowlist secret

  sku_name   = "GP_Standard_D2s_v3"
  storage_mb = 32768

  # INJECTED DEFECT: Public network access enabled on enterprise database
  public_network_access_enabled = true

  depends_on = [azurerm_private_dns_zone_virtual_network_link.dns_link]
}
