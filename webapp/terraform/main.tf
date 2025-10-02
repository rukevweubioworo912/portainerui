
data "azurerm_resource_group" "k8s_rg" {
  name = var.resource_group_name
}

resource "azurerm_virtual_network" "k8s_vnet" {
  name                = "k8s-vnet"
  address_space       = [var.vnet_cidr]
  location            = data.azurerm_resource_group.k8s_rg.location
  resource_group_name = data.azurerm_resource_group.k8s_rg.name
}

resource "azurerm_subnet" "k8s_subnet" {
  name                 = "k8s-subnet"
  resource_group_name  = data.azurerm_resource_group.k8s_rg.name
  virtual_network_name = azurerm_virtual_network.k8s_vnet.name
  address_prefixes     = [var.subnet_cidr]
}

resource "azurerm_network_security_group" "k8s_nsg" {
  name                = "k8s-nsg"
  location            = data.azurerm_resource_group.k8s_rg.location
  resource_group_name = data.azurerm_resource_group.k8s_rg.name

  # SSH from internet
  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Kubernetes API Server
  security_rule {
    name                       = "KubeAPI"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # NodePort Services
  security_rule {
    name                       = "NodePort"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow all internal VNet traffic
  security_rule {
    name                       = "AllowVNetInternal"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.vnet_cidr
    destination_address_prefix = "*"
  }

  # Allow all outbound
  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Master VM Resources
resource "azurerm_public_ip" "master_pip" {
  name                = "master-pip"
  location            = data.azurerm_resource_group.k8s_rg.location
  resource_group_name = data.azurerm_resource_group.k8s_rg.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "master_nic" {
  name                = "master-nic"
  location            = data.azurerm_resource_group.k8s_rg.location
  resource_group_name = data.azurerm_resource_group.k8s_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.k8s_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.master_pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "master_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.master_nic.id
  network_security_group_id = azurerm_network_security_group.k8s_nsg.id
}

resource "azurerm_linux_virtual_machine" "master_vm" {
  name                  = "k8s-master"
  resource_group_name   = data.azurerm_resource_group.k8s_rg.name
  location              = data.azurerm_resource_group.k8s_rg.location
  size                  = var.vm_size_master
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.master_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  disable_password_authentication = false
}

# Worker VMs (2)
resource "azurerm_public_ip" "worker_pip" {
  count               = 2
  name                = "worker-pip-${count.index}"
  location            = data.azurerm_resource_group.k8s_rg.location
  resource_group_name = data.azurerm_resource_group.k8s_rg.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "worker_nic" {
  count               = 2
  name                = "worker-nic-${count.index}"
  location            = data.azurerm_resource_group.k8s_rg.location
  resource_group_name = data.azurerm_resource_group.k8s_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.k8s_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.worker_pip[count.index].id
  }
}

resource "azurerm_network_interface_security_group_association" "worker_nsg_assoc" {
  count                     = 2
  network_interface_id      = azurerm_network_interface.worker_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.k8s_nsg.id
}

resource "azurerm_linux_virtual_machine" "worker_vm" {
  count                 = 2
  name                  = "k8s-worker-${count.index}"
  resource_group_name   = data.azurerm_resource_group.k8s_rg.name
  location              = data.azurerm_resource_group.k8s_rg.location
  size                  = var.vm_size_worker
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.worker_nic[count.index].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  disable_password_authentication = false
}