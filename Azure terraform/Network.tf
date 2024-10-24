terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.115.0"
    }
  }
}

# Provider Configuration
provider "azurerm" {
  features {}
  alias           = "A"
  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

provider "azurerm" {
  features {}
  alias           = "vhub"
  client_id       = var.client_id_vhub
  client_secret   = var.client_secret_vhub
  subscription_id = var.subscription_id_vhub
  tenant_id       = var.tenant_id_vhub
}

variable "client_id" {
  type        = string
  description = "The client ID for the Azure service principal."
  default     = ""
}

variable "client_secret" {
  type        = string
  description = "The client secret for the Azure service principal."
  default     = ""
}

variable "subscription_id" {
  type        = string
  description = "The subscription ID for the Azure account."
  default     = ""
}

variable "tenant_id" {
  type        = string
  description = "The tenant ID for the Azure account."
  default     = ""
}

variable "client_id_vhub" {
  type        = string
  description = "The client ID for the Azure service principal."
  default     = ""
}

variable "client_secret_vhub" {
  type        = string
  description = "The client secret for the Azure service principal."
  default     = ""
}

variable "subscription_id_vhub" {
  type        = string
  description = "The subscription ID for the Azure account."
  default     = ""
}

variable "tenant_id_vhub" {
  type        = string
  description = "The tenant ID for the Azure account."
  default     = ""
}


variable "service_code" {
  type        = string
  description = "단위서비스코드"
  default     = "cloudwiz"
}

variable "environment" {
  type        = string
  description = "환경(dev, prd)"
  default     = "prd"
}

variable "service_name" {
  type        = string
  description = "단위서비스 영문약어"
  default     = "cloudwiz"
}

variable "service_grade" {
  type        = string
  description = "단위서비스 등급"
  default     = "B"
}

variable "cidr" {
  type        = number
  description = "CIDR 입력, ex)23,24,25"
  default     = 25
}

variable "third_octet" {
  type        = number
  description = "10.241.x.0/23 의 x값"
  default     = 184
}

data "azurerm_resource_group" "rg-az01-co013601-azgov-network-01" {
	provider = azurerm.vhub
	name = "rg-az01-co013601-azgov-network-01"
}

data "azurerm_virtual_hub" "vhub-az01-azgov-01" {
  provider = azurerm.vhub
	name = "vhub-az01-azgov-01"
	resource_group_name = data.azurerm_resource_group.rg-az01-co013601-azgov-network-01.name
}

# Resource Group Creation
resource "azurerm_resource_group" "rg" {
  name     = format("rg-az01-%s-%s-%s-01", var.service_code, var.environment, var.service_name)
  location = "Korea Central" # Update as needed
  provider = azurerm.A
}

data "azurerm_resource_group" "rg" {
  name     = format("rg-az01-%s-%s-%s-01", var.service_code, var.environment, var.service_name)
  provider = azurerm.A
}

# Virtual Network Creation
resource "azurerm_virtual_network" "vnet" {
  name                = format("vnet-az01-%s-%s-01", var.environment, var.service_name)
  address_space       = [format("10.241.%d.0/%d", var.third_octet, var.cidr)]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  provider            = azurerm.A
}

data "azurerm_virtual_network" "vnet" {
  name                = format("vnet-az01-%s-%s-01", var.environment, var.service_name)
  resource_group_name = data.azurerm_resource_group.rg.name
  provider            = azurerm.A
}

# Subnets Creation with Conditions
resource "azurerm_subnet" "sbn_appgw" {
  provider             = azurerm.A
  name                 = format("sbn-az01-%s-%s-appgw", var.environment, var.service_name)
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [
    var.cidr == 23 ? format("10.241.%d.0/27", var.third_octet) :
    var.cidr == 24 ? format("10.241.%d.0/27", var.third_octet) :
    format("10.241.%d.0/27", var.third_octet)  # default for 25
  ]
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_subnet" "sbn_lb" {
  provider             = azurerm.A
  name                 = format("sbn-az01-%s-%s-lb", var.environment, var.service_name)
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [
    var.cidr == 23 ? format("10.241.%d.32/28", var.third_octet) :
    var.cidr == 24 ? format("10.241.%d.32/28", var.third_octet) :
    format("10.241.%d.112/28", var.third_octet)  # default for 25
  ]
}

resource "azurerm_subnet" "sbn_app" {
  provider             = azurerm.A
  name                 = format("sbn-az01-%s-%s-app", var.environment, var.service_name)
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes = [
    var.cidr == 23 ? format("10.241.%d.0/24", var.third_octet + 1) :  # 세 번째 옥텟 +1
    var.cidr == 24 ? format("10.241.%d.128/25", var.third_octet) :
    format("10.241.%d.32/27", var.third_octet)  # default for 25
  ]
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_subnet" "sbn_db" {
  provider             = azurerm.A
  name                 = format("sbn-az01-%s-%s-db", var.environment, var.service_name)
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [
    var.cidr == 23 ? format("10.241.%d.128/25", var.third_octet) :
    var.cidr == 24 ? format("10.241.%d.64/27", var.third_octet) :
    format("10.241.%d.64/28", var.third_octet)  # default for 25
  ]
  
  # delegation {
  #   name = "pgdb-delegation"
  #   service_delegation {
  #     name = "Microsoft.DBforPostgreSQL/flexibleServers"
  #     actions = [
  #       "Microsoft.Network/virtualNetworks/subnets/join/action",
  #     ]
  #   }
  # }

  delegation {
    name = "mydb-delegation"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
}

# Subnets Creation
data "azurerm_subnet" "sbn_db" {
  provider             = azurerm.A
  name                 = format("sbn-az01-%s-%s-db", var.environment, var.service_name)
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
}


resource "azurerm_subnet" "sbn_pe" {
  provider             = azurerm.A
  name                 = format("sbn-az01-%s-%s-pe", var.environment, var.service_name)
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [
    var.cidr == 23 ? format("10.241.%d.48/28", var.third_octet) :
    var.cidr == 24 ? format("10.241.%d.96/27", var.third_octet) :
    format("10.241.%d.80/28", var.third_octet)  # default for 25
  ]
}

data "azurerm_subnet" "sbn_pe" {
  provider             = azurerm.A
  name                 = format("sbn-az01-%s-%s-pe", var.environment, var.service_name)
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
}

resource "azurerm_subnet" "sbn_etc" {
  provider             = azurerm.A
  name                 = format("sbn-az01-%s-%s-etc", var.environment, var.service_name)
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [
    var.cidr == 23 ? format("10.241.%d.64/26", var.third_octet) :
    var.cidr == 24 ? format("10.241.%d.48/28", var.third_octet) :
    format("10.241.%d.96/28", var.third_octet)  # default for 25
  ]
}

# UDR (User Defined Route) Creation
resource "azurerm_route_table" "udr_appgw" {
  provider            = azurerm.A
  name                = format("udr-az01-%s-%s-appgw", var.environment, var.service_name)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  route {
    next_hop_type  = "Internet"
    address_prefix = "0.0.0.0/0"
    name           = "appgw-internet"
  }
}

resource "azurerm_route_table" "udr_app" {
  provider            = azurerm.A
  name                = format("udr-az01-%s-%s-app", var.environment, var.service_name)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  route {
    address_prefix         = "0.0.0.0/0"
    next_hop_in_ip_address = "10.241.4.132"
    next_hop_type          = "VirtualAppliance"
    name                   = "app-internet"
  }
}

# Subnet Route Table Associations
resource "azurerm_subnet_route_table_association" "assoc_appgw" {
  provider       = azurerm.A
  subnet_id      = azurerm_subnet.sbn_appgw.id
  route_table_id = azurerm_route_table.udr_appgw.id
}

resource "azurerm_subnet_route_table_association" "assoc_app" {
  provider       = azurerm.A
  subnet_id      = azurerm_subnet.sbn_app.id
  route_table_id = azurerm_route_table.udr_app.id
}

resource "azurerm_virtual_hub_connection" "vhub-connection-01" {
  provider = azurerm.A
	remote_virtual_network_id = azurerm_virtual_network.vnet.id
	virtual_hub_id = data.azurerm_virtual_hub.vhub-az01-azgov-01.id
	name = format("vhub-az01-%s-connection-01", var.service_name)
  depends_on = [azurerm_virtual_network.vnet]
}