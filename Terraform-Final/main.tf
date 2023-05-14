# Conexão com os providers
terraform {
    required_providers {
        azurerm = {
            source = "azurerm"
            version = "~> 2.65"
        }
    }
}

provider "azurerm" {
  features {}
}

# Criação de grupo de recursos
resource "azurerm_resource_group" "default" {
    name = var.rg
    location = var.locat
    tags = {
        "env": "staging"
        "project": "azureexpert"
    }
}


# Criação de rede virtual
resource "azurerm_virtual_network" "default" {
    name = "vnet-devops"
    address_space = ["10.0.0.0/16"]
    location =  var.locat
    resource_group_name = azurerm_resource_group.default.name
        tags = {
            "env": "staging"
            "project": "azureexpert"
        }
}

# Criação de sub-rede interna
resource "azurerm_subnet" "internal" {
    name = "internal"
    resource_group_name = azurerm_resource_group.default.name
    virtual_network_name = azurerm_virtual_network.default.name
    address_prefixes = ["10.0.1.0/24"]
}

# Criação de sub-rede staging
resource "azurerm_subnet" "staging" {
    name = "staging"
    resource_group_name = azurerm_resource_group.default.name
    virtual_network_name = azurerm_virtual_network.default.name
    address_prefixes = ["10.0.10.0/24"]
    
}

# Configuração de ip público para a máquina
resource "azurerm_public_ip" "default" {
  name                = "${var.vm}-pi"
  resource_group_name = var.rg
  location            = var.locat
  allocation_method   = "Static"
}

# Alteração no grupo de segurança
resource "azurerm_network_security_group" "default" {
  name                = "${var.vm}-nsg"
  location            = var.locat
  resource_group_name = var.rg

  security_rule {
    name                       = "SSH"
    priority                   = "200"
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Atribuição de ip para a máquina virtual
resource "azurerm_network_interface" "default" {
  name                = "${var.vm}-nic"
  location            = var.locat
  resource_group_name = var.rg

  ip_configuration {
    name                          = "${var.vm}-ipconfig"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.default.id
  }
}


# Atribuição da interface de segurança para a máquina virtual

resource "azurerm_network_interface_security_group_association" "default" {
  network_interface_id      = azurerm_network_interface.default.id
  network_security_group_id = azurerm_network_security_group.default.id
}

# Criação da máquina virtual
resource "azurerm_virtual_machine" "default" {
    
  name                  = var.vm
  location              = var.locat
  resource_group_name   = var.rg
  network_interface_ids = [azurerm_network_interface.default.id]
  vm_size               = "Standard_B1s"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = var.vm
    admin_username = "useraz"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }

}