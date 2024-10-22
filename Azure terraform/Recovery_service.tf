# 변수 정의
variable "backupPolicies" {
  description = "Recovery service vault backup policy"
  type = list(object({
    name                    = string
    scheduleRunTimes        = list(string)
    dailyRetentionCount     = number
    weeklyRetentionCount    = number
    weeklyDaysOfTheWeek     = list(string)
    monthlyRetentionCount   = number
    monthlyDaysOfTheWeek    = list(string)
    monthlyWeeksOfTheMonth  = list(string)
    yearlyRetentionCount    = number
    yearlyDaysOfTheWeek     = list(string)
    yearlyWeeksOfTheMonth   = list(string)
    yearlyMonthsOfYear      = list(string)
  }))
  default = [
    {
      name                    = "policy1"
      scheduleRunTimes        = ["2023-01-01T23:00:00Z"]
      dailyRetentionCount     = 10
      weeklyRetentionCount    = 6
      weeklyDaysOfTheWeek     = ["Sunday", "Wednesday", "Friday", "Saturday"]
      monthlyRetentionCount   = 7
      monthlyDaysOfTheWeek    = ["Sunday", "Wednesday"]
      monthlyWeeksOfTheMonth  = ["First", "Last"]
      yearlyRetentionCount    = 77
      yearlyDaysOfTheWeek     = ["Sunday"]
      yearlyWeeksOfTheMonth   = ["Last"]
      yearlyMonthsOfYear      = ["January"]
    },
    {
      name                    = "policy2"
      scheduleRunTimes        = ["2023-01-01T23:00:00Z"]
      dailyRetentionCount     = 7
      weeklyRetentionCount    = 4
      weeklyDaysOfTheWeek     = ["Monday", "Thursday"]
      monthlyRetentionCount   = 3
      monthlyDaysOfTheWeek    = ["Monday"]
      monthlyWeeksOfTheMonth  = ["Second"]
      yearlyRetentionCount    = 10
      yearlyDaysOfTheWeek     = ["Monday"]
      yearlyWeeksOfTheMonth   = ["First"]
      yearlyMonthsOfYear      = ["February"]
    }
  ]
}

# Recovery Services Vault 생성
resource "azurerm_recovery_services_vault" "rsvault" {
  provider            = azurerm.A
  name                = format("rsvt-az01-%s-%s-01", var.environment, var.service_name)
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  sku = "RS0"
  soft_delete_enabled = true
}

# Backup Policy VM 생성
resource "azurerm_backup_policy_vm" "bp_vm" {
  provider            = azurerm.A
  count               = length(var.backupPolicies)
  name                = var.backupPolicies[count.index].name
  resource_group_name = data.azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.rsvault.name

  timezone = "UTC"

  # Backup Schedule 설정
  backup {
    frequency = "Daily"
    # 시간 값만 추출하여 'HH:mm' 형식으로 변환
    time      = substr(var.backupPolicies[count.index].scheduleRunTimes[0], 11, 5)
  }

  # Daily Retention 설정
  retention_daily {
    count = var.backupPolicies[count.index].dailyRetentionCount
  }

  # Weekly Retention 설정
  retention_weekly {
    count    = var.backupPolicies[count.index].weeklyRetentionCount
    weekdays = var.backupPolicies[count.index].weeklyDaysOfTheWeek
  }

  # Monthly Retention 설정
  retention_monthly {
    count    = var.backupPolicies[count.index].monthlyRetentionCount
    weekdays = var.backupPolicies[count.index].monthlyDaysOfTheWeek
    weeks    = var.backupPolicies[count.index].monthlyWeeksOfTheMonth
  }

  # Yearly Retention 설정
  retention_yearly {
    count    = var.backupPolicies[count.index].yearlyRetentionCount
    weekdays = var.backupPolicies[count.index].yearlyDaysOfTheWeek
    weeks    = var.backupPolicies[count.index].yearlyWeeksOfTheMonth
    months   = var.backupPolicies[count.index].yearlyMonthsOfYear
  }
}

# Private Endpoint 생성
resource "azurerm_private_endpoint" "rs_pe" {
  provider = azurerm.A
  name                = format("pe-rsvt-az01-%s-%s-01", var.environment, var.service_name)
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.sbn_pe.id

  private_service_connection {
    name                           = format("pe-rsvt-az01-%s-%s-connection", var.environment, var.service_name)
    private_connection_resource_id = azurerm_recovery_services_vault.rsvault.id
    subresource_names              = ["AzureBackup"]
    is_manual_connection           = false
  }
}

# Output 생성
output "recovery_services_vault_id" {
  value = azurerm_recovery_services_vault.rsvault.id
}

output "private_endpoint_rs_pe_id" {
  value = azurerm_private_endpoint.rs_pe.id
}
