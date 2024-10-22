variable "db_version" {
  type        = string
  description = "The PostgreSQL version for the flexible server."
  default     = "8.0.21"
}

variable "db_admin_login" {
  type        = string
  description = "The administrator login for the PostgreSQL server."
  default     = "ktadmin"
}

variable "db_admin_password" {
  type        = string
  description = "The administrator password for the PostgreSQL server."
  default     = "KTP@ssw0rd123"
}

variable "db_sku_name" {
  type        = string
  description = "The SKU name for the Mysql flexible server."
  default     = "GP_Standard_D2ds_v4"
}

variable "db_storage_gb" {
  type        = number
  description = "The storage size in MB for the PostgreSQL server."
  default     = 128
}

variable "db_zone" {
  type        = string
  description = "Zone 갯수 설정"
  default     = "2"
}

variable "db_high_availability" {
  type        = string
  description = "DB 고가용성 설정"
  default     = "SameZone"  # ZoneRedundant, SameZone 
}

# Subnets Creation
data "azurerm_subnet" "sbn_db" {
  provider             = azurerm.A
  name                 = format("sbn-az01-%s-%s-db", var.environment, var.service_name)
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
}

data "azurerm_subnet" "sbn_pe" {
  provider             = azurerm.A
  name                 = format("sbn-az01-%s-%s-pe", var.environment, var.service_name)
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
}

data "azurerm_resource_group" "rg_mysqldb_pe" {
  name     = "rg-az01-co013601-azgov-network-01"
  provider = azurerm.A
}

# MySQL Flexible Server 생성
resource "azurerm_mysql_flexible_server" "mydb" {
  provider            = azurerm.A
  name                   = format("mydb-az01-%s-%s-01", var.environment, var.service_name)
  location               = data.azurerm_resource_group.rg.location
  resource_group_name    = data.azurerm_resource_group.rg.name
  version                = var.db_version
  administrator_login    = var.db_admin_login
  administrator_password = var.db_admin_password
  backup_retention_days  = 7
  geo_redundant_backup_enabled = false
  sku_name               = var.db_sku_name
  zone                   = var.db_zone


  storage {
    size_gb              = var.db_storage_gb
    auto_grow_enabled    = true
    io_scaling_enabled   = true
  }

  high_availability {
    mode = var.db_high_availability  # ZoneRedundant 또는 SameZone 옵션 사용
  }

  tags = {
    Name          = format("mydb-az01-%s-%s-01", var.environment, var.service_name)
    Service       = var.service_name
    ServiceGrade  = var.service_grade
    Environment   = var.environment
  }

  delegated_subnet_id    = azurerm_subnet.sbn_db.id  # 기존 서브넷 사용
}

# MySQL Flexible Database 생성
resource "azurerm_mysql_flexible_database" "mysql_test_db" {
  provider            = azurerm.A
  name                = "mysql-test-db"
  resource_group_name = data.azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mydb.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}


# data "azurerm_private_dns_zone" "dns-zone" {
#   provider            = azurerm.A
#   name                = "privatelink.mysql.database.azure.com"
#   resource_group_name = data.azurerm_resource_group.rg_mysqldb_pe.name
# }

# resource "azurerm_private_dns_a_record" "mydb" {
#   provider            = azurerm.A
#   name                = format("mydb-az01-%s-%s-01", var.environment, var.service_name)
#   zone_name           = data.azurerm_private_dns_zone.dns-zone.name
#   resource_group_name = data.azurerm_resource_group.rg_mysqldb_pe.name
#   ttl                 = 10
#   records             = [azurerm_private_endpoint.pe-mydb.private_service_connection[0].private_ip_address]
# }

# resource "azurerm_private_endpoint" "pe-mydb" {
#   provider            = azurerm.A
#   name                = format("pe-mydb-az01-%s-%s-01", var.environment, var.service_name)
#   location            = data.azurerm_resource_group.rg.location
#   resource_group_name = data.azurerm_resource_group.rg.name
#   subnet_id           = azurerm_subnet.sbn_pe.id

#   private_service_connection {
#     name                           = "privateserviceconnection"
#     private_connection_resource_id = azurerm_mysql_flexible_server.mydb.id
#     subresource_names              = ["mysqlServer"]
#     is_manual_connection           = false
#   }
# }