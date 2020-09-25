provider "azurerm" {
	features {}
}

resource "azurerm_resource_group" "RG2" {
	name	 = "RG2"
	location = "westus2"
}

resource "azurerm_virtual_network" "RG2d-vnet" {
	name 							= "RG2-vnet"
	resource_group_name             = "RG2"
	address_space					= ["10.0.0.0/24"]
	location                        = "westus2"
	depends_on 						= [ azurerm_resource_group.RG2 ]
	
}

resource "azurerm_subnet" "RG2d-default" {
	name							= "default"
	resource_group_name             = "RG2"
	virtual_network_name			= "RG2-vnet"
	address_prefixes				= ["10.0.0.0/24"]
	depends_on 						= [ azurerm_resource_group.RG2 , azurerm_virtual_network.RG2d-vnet  ]
}

resource "azurerm_public_ip" "terradvm1-pub-ip" {
  name                    = "terravm1-pub-ip"
  location                = azurerm_resource_group.RG2.location
  resource_group_name     = azurerm_resource_group.RG2.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30
  
  depends_on 		      = [ azurerm_resource_group.RG2 , azurerm_virtual_network.RG2d-vnet , azurerm_subnet.RG2d-default ]
  
}


resource "azurerm_network_interface" "terradvm1-nic" {
	name							= "terravm1389"
	location                        = "westus2"
	resource_group_name             = "RG2"
	
	ip_configuration {
    name                          	= "internal"
    subnet_id                     	= azurerm_subnet.RG2d-default.id
    private_ip_address_allocation 	= "Dynamic"
	public_ip_address_id			= azurerm_public_ip.terradvm1-pub-ip.id
  }
    depends_on 						= [ azurerm_resource_group.RG2 , azurerm_virtual_network.RG2d-vnet , azurerm_subnet.RG2d-default , azurerm_public_ip.terradvm1-pub-ip  ]
}


resource "azurerm_linux_virtual_machine" "terradvm1" {
	admin_username                  = "azureuser"
	location                        = "westus2"
	name                            = "terravm1"
	resource_group_name             = "RG2"
	size                            = "Standard_B1s"
	network_interface_ids			= [ azurerm_network_interface.terradvm1-nic.id, ]
	
	admin_ssh_key {
		public_key = file("~/.ssh/id_rsa.pub")
		username   = "azureuser"
	}
	
    os_disk {
        caching                   = "ReadWrite"
        storage_account_type      = "Standard_LRS"
        write_accelerator_enabled = false
    }
	
	source_image_reference {
        offer     = "UbuntuServer"
        publisher = "Canonical"
        sku       = "18.04-LTS"
        version   = "latest"
    }


}


resource "local_file" "inventory" {

	content = <<EOT
	[instance]
	${azurerm_linux_virtual_machine.terradvm1.public_ip_address}
	EOT
	
	filename = "inv"
	
}


resource "null_resource" "ansible-docker" {

  depends_on = [azurerm_linux_virtual_machine.terradvm1, local_file.inventory]

  provisioner "local-exec" {
    command = "sleep 120; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u 'azureuser' -i inv vm_tools_setup.yml"
  }
}
