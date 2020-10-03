resource "azurerm_log_analytics_workspace" "alganwsp1" {
    name = "lganwsp1"
    resource_group_name = "RG2"
    location = "westus2"
    sku ="PerGB2018"

}