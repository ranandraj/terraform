resource "azurerm_log_analytics_workspace" "alganwsp1" {
    name = "lganwsp1"
    resource_group_name = "RG2"
    location = "westus2"
    sku ="PerGB2018"

}

resource "azurerm_log_analytics_solution" "algansl1" {
    solution_name = "ContainerInsights"
    resource_group_name = "RG2"
    location = "westus2"
    workspace_resource_id = azurerm_log_analytics_workspace.alganwsp1.id 
    workspace_name = azurerm_log_analytics_workspace.alganwsp1.name

    plan {
        publisher = "Microsoft"
        product = "OMSGallery/ContainerInsights"
    }
}