resource "azurerm_storage_account" "storageaccount" {
  provider                 = azurerm.A
  name                     = format("staz01%s%s01", var.environment, var.service_name)
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    Name          = format("staz01%s%s01", var.environment, var.service_name)
    Service       = var.service_name
    ServiceGrade  = var.service_grade
    Environment   = var.environment
  }

}