resource "azurerm_resource_group" "epicbook" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "epicbook" {
  name                = "week10-epicbook-vnet"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.epicbook.location
  resource_group_name = azurerm_resource_group.epicbook.name
}

resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.epicbook.name
  virtual_network_name = azurerm_virtual_network.epicbook.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "backend"
  resource_group_name  = azurerm_resource_group.epicbook.name
  virtual_network_name = azurerm_virtual_network.epicbook.name
  address_prefixes     = ["10.10.2.0/24"]
}

resource "azurerm_subnet" "mysql" {
  name                 = "mysql"
  resource_group_name  = azurerm_resource_group.epicbook.name
  virtual_network_name = azurerm_virtual_network.epicbook.name
  address_prefixes     = ["10.10.3.0/24"]

  delegation {
    name = "mysql-flexible-server"

    service_delegation {
      name    = "Microsoft.DBforMySQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_public_ip" "frontend" {
  name                = "week10-epicbook-frontend-pip"
  location            = azurerm_resource_group.epicbook.location
  resource_group_name = azurerm_resource_group.epicbook.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "backend" {
  name                = "week10-epicbook-backend-pip"
  location            = azurerm_resource_group.epicbook.location
  resource_group_name = azurerm_resource_group.epicbook.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "frontend" {
  name                = "week10-epicbook-frontend-nsg"
  location            = azurerm_resource_group.epicbook.location
  resource_group_name = azurerm_resource_group.epicbook.name

  security_rule {
    name                       = "SSHFromAgent"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh_allowed_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "PublicHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "backend" {
  name                = "week10-epicbook-backend-nsg"
  location            = azurerm_resource_group.epicbook.location
  resource_group_name = azurerm_resource_group.epicbook.name

  security_rule {
    name                       = "SSHFromAgent"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh_allowed_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "NodeFromFrontend"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "10.10.1.0/24"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "frontend" {
  name                = "week10-epicbook-frontend-nic"
  location            = azurerm_resource_group.epicbook.location
  resource_group_name = azurerm_resource_group.epicbook.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.frontend.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.frontend.id
  }
}

resource "azurerm_network_interface" "backend" {
  name                = "week10-epicbook-backend-nic"
  location            = azurerm_resource_group.epicbook.location
  resource_group_name = azurerm_resource_group.epicbook.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.backend.id
  }
}

resource "azurerm_network_interface_security_group_association" "frontend" {
  network_interface_id      = azurerm_network_interface.frontend.id
  network_security_group_id = azurerm_network_security_group.frontend.id
}

resource "azurerm_network_interface_security_group_association" "backend" {
  network_interface_id      = azurerm_network_interface.backend.id
  network_security_group_id = azurerm_network_security_group.backend.id
}

resource "azurerm_linux_virtual_machine" "frontend" {
  name                            = "week10-epicbook-frontend"
  resource_group_name             = azurerm_resource_group.epicbook.name
  location                        = azurerm_resource_group.epicbook.location
  size                            = "Standard_B1s"
  admin_username                  = var.admin_user
  network_interface_ids           = [azurerm_network_interface.frontend.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_user
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "week10-epicbook-frontend-os"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "backend" {
  name                            = "week10-epicbook-backend"
  resource_group_name             = azurerm_resource_group.epicbook.name
  location                        = azurerm_resource_group.epicbook.location
  size                            = "Standard_B1s"
  admin_username                  = var.admin_user
  network_interface_ids           = [azurerm_network_interface.backend.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_user
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "week10-epicbook-backend-os"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

resource "azurerm_private_dns_zone" "mysql" {
  name                = "epicbook10.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.epicbook.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = "epicbook-vnet-link"
  resource_group_name   = azurerm_resource_group.epicbook.name
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = azurerm_virtual_network.epicbook.id
}

resource "azurerm_mysql_flexible_server" "epicbook" {
  name                   = var.mysql_server_name
  resource_group_name    = azurerm_resource_group.epicbook.name
  location               = azurerm_resource_group.epicbook.location
  administrator_login    = "epicbookadmin"
  administrator_password = var.mysql_admin_password
  backup_retention_days  = 7
  delegated_subnet_id    = azurerm_subnet.mysql.id
  private_dns_zone_id    = azurerm_private_dns_zone.mysql.id
  sku_name               = "B_Standard_B1ms"
  version                = "8.0.21"

  storage {
    size_gb = 20
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.mysql]
}

resource "azurerm_mysql_flexible_database" "bookstore" {
  name                = "bookstore"
  resource_group_name = azurerm_resource_group.epicbook.name
  server_name         = azurerm_mysql_flexible_server.epicbook.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}
