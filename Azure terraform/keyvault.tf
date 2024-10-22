variable "skuName" {
  description = "The SKU of the vault to be created."
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.skuName)
    error_message = "Allowed values are 'standard' or 'premium'."
  }
}

# Azure Key Vault 리소스
resource "azurerm_key_vault" "vault" {
  provider             = azurerm.A
  name                = format("az01-%s-%s-kv-01", var.environment, var.service_name)
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tenant_id           = var.tenant_id

  sku_name = var.skuName

  soft_delete_retention_days       = 90
  purge_protection_enabled         = false
  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
  enable_rbac_authorization        = true
  enabled_for_deployment           = false
  enabled_for_disk_encryption      = false
  enabled_for_template_deployment  = false
}

# Key Vault에 대한 Private Endpoint
resource "azurerm_private_endpoint" "pe" {
  provider            = azurerm.A
  name                = format("pe-kv-az01-%s-%s-kv-01", var.environment, var.service_name)
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.sbn_pe.id

  private_service_connection {
    name                           = "vault"
    private_connection_resource_id = azurerm_key_vault.vault.id
    subresource_names              = ["vault"]
    is_manual_connection = false
  }
}

# Key Vault ID 출력
output "key_vault_id" {
  value = azurerm_key_vault.vault.id
}

# Private Endpoint ID 출력
output "private_endpoint_id" {
  value = azurerm_private_endpoint.pe.id
}