# Variables for PostgreSQL Flexible Server Configuration
variable "pgdb_version" {
  type        = string
  description = "The PostgreSQL version for the flexible server."
  default     = "15"
}

variable "pgdb_admin_login" {
  type        = string
  description = "The administrator login for the PostgreSQL server."
  default     = "ktadmin"
}

variable "pgdb_admin_password" {
  type        = string
  description = "The administrator password for the PostgreSQL server."
  default     = "KTP@ssw0rd123"
}

variable "pgdb_sku_name" {
  type        = string
  description = "The SKU name for the PostgreSQL flexible server."
  default     = "GP_Standard_D4ds_v5"
}

variable "pgdb_storage_mb" {
  type        = number
  description = "The storage size in MB for the PostgreSQL server."
  default     = 32768
}

variable "pgdb_zone" {
  type        = string
  description = "Zone 갯수 설정"
  default     = "3"
}

variable "pbdb_high_availability" {
  type        = string
  description = "DB 고가용성 설정"
  default     = "ZoneRedundant"  # ZoneRedundant, SameZone 
}


data "azurerm_resource_group" "rg_postgresdb_pe" {
  name     = "rg-az01-co013601-azgov-network-01"
  provider = azurerm.A
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "pgdb" {
  provider               = azurerm.A
  name                   = format("pgdb-az01-%s-%s-01", var.environment, var.service_name)
  location               = data.azurerm_resource_group.rg.location
  resource_group_name    = data.azurerm_resource_group.rg.name
  version                = var.pgdb_version
  administrator_login    = var.pgdb_admin_login
  administrator_password = var.pgdb_admin_password
  sku_name               = var.pgdb_sku_name
  storage_mb             = var.pgdb_storage_mb
  public_network_access_enabled = false
  zone                   = var.pgdb_zone

  high_availability {
    mode = var.pbdb_high_availability  # ZoneRedundant 또는 SameZone 옵션 사용
  }

  tags = {
    Name          = format("pgdb-az01-%s-%s-01", var.environment, var.service_name)
    Service       = var.service_name
    ServiceGrade  = var.service_grade
    Environment   = var.environment
  }
}


resource "azurerm_postgresql_flexible_server_database" "pgdb" {
  provider  = azurerm.A
  name      = format("pgdb-az01-%s-%s-01", var.environment, var.service_name)
  server_id = azurerm_postgresql_flexible_server.pgdb.id
  charset   = "UTF8"
  collation = "en_US.utf8"

}

data "azurerm_private_dns_zone" "dns-zone" {
  provider            = azurerm.A
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.rg_postgresdb_pe.name
}

resource "azurerm_private_dns_a_record" "pgdb" {
  provider            = azurerm.A
  name                = format("pgdb-az01-%s-%s-01", var.environment, var.service_name)
  zone_name           = data.azurerm_private_dns_zone.dns-zone.name
  resource_group_name = data.azurerm_resource_group.rg_postgresdb_pe.name
  ttl                 = 10
  records             = [azurerm_private_endpoint.pe-pgdb.private_service_connection[0].private_ip_address]
}

resource "azurerm_private_endpoint" "pe-pgdb" {
  provider            = azurerm.A
  name                = format("pe-pgdb-az01-%s-%s-01", var.environment, var.service_name)
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.sbn_pe.id

  private_service_connection {
    name                           = "privateserviceconnection"
    private_connection_resource_id = azurerm_postgresql_flexible_server.pgdb.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }
}

