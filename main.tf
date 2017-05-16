variable "admin_password" {
  default = "iosjdaaosudj##@@123456"
}
variable "admin_username" {
  default = "terraformuser"
}
variable "rgr_name" {
  default = "terraform-resourcegroup42"
}
variable "sta_name" {
  default = "fundamentalstore42"
}
variable "vm_name" {
  default = "Terraform-SH42"
}
variable "vm_size" {
  default = "Standard_A2_v2"
}
variable "dsc_registration_url" {
  default = "https://we-agentservice-prod-1.azure-automation.net/accounts/bc391f81-a4d1-4aeb-b55b-90a15f08a189"
}
variable "dsc_registration_key" {
  default = "KeQw8wMk3IVgtt+RmzNB+BSHmbdvKKMLmFecnVJ80S1MuNfQ6nQaO206QO+LWPRvEI+NGOgKNLljU/aOou7iOA=="
}
variable "dsc_configuration_name" {
  default = "SessionHost.localhost"
}  
variable "location" {
  default = "West Europe"
}  
variable "tag_environment" {
  default = "West Europe"
} 
variable "vm_subnet_id" {
  default = "/subscriptions/733a1ea1-2d00-45b8-a6f3-c05a5ef2d5c3/resourceGroups/rgr-jacob-network/providers/Microsoft.Network/virtualNetworks/vNet-Jacob/subnets/sessionhost"
}  

resource "azurerm_resource_group" "fundamentals" {
  name     = "${var.rgr_name}"
  location = "${var.location}"

  tags {
    terraformManaged = "true"
    environment      = "${var.tag_environment}"
  }
}

resource "azurerm_network_interface" "fundamentals" {
  name                = "${var.vm_name}-NIC-01"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.fundamentals.name}"

  ip_configuration {
    name                          = "Standard"
    subnet_id                     = "${var.vm_subnet_id}"
    private_ip_address_allocation = "dynamic"
  }

  tags {
    terraformManaged = "true"
    environment      = "${var.tag_environment}"
  }
}

resource "azurerm_storage_account" "fundamentals" {
  name                = "${var.sta_name}"
  resource_group_name = "${azurerm_resource_group.fundamentals.name}"
  location            = "${var.location}"
  account_type        = "Standard_LRS"

  tags {
    terraformManaged = "true"
    environment      = "${var.tag_environment}"
  }
}

resource "azurerm_storage_container" "fundamentals" {
  name                  = "vhds"
  resource_group_name   = "${azurerm_resource_group.fundamentals.name}"
  storage_account_name  = "${azurerm_storage_account.fundamentals.name}"
  container_access_type = "private"
}

resource "azurerm_virtual_machine" "fundamentals" {
  name                  = "${var.vm_name}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.fundamentals.name}"
  network_interface_ids = ["${azurerm_network_interface.fundamentals.id}"]
  vm_size               = "${var.vm_size}"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name          = "${var.vm_name}"
    vhd_uri       = "${azurerm_storage_account.fundamentals.primary_blob_endpoint}${azurerm_storage_container.fundamentals.name}/${var.vm_name}-osdisk.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
    disk_size_gb = "130"
  }

  storage_data_disk {
    name          = "${var.vm_name}-datadisk-01"
    vhd_uri       = "${azurerm_storage_account.fundamentals.primary_blob_endpoint}${azurerm_storage_container.fundamentals.name}/${var.vm_name}-datadisk-01.vhd"
    create_option = "Empty"
    disk_size_gb  = "1023"
    lun           = "0"
  }

  os_profile {
    computer_name  = "${var.vm_name}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }


  tags {
    terraformManaged = "true"
    environment      = "${var.tag_environment}"
  }
}


resource "azurerm_virtual_machine_extension" "fundamentals" {
  name                       = "${azurerm_virtual_machine.fundamentals.name}"
  location                   = "${var.location}"
  resource_group_name        = "${azurerm_resource_group.fundamentals.name}"
  virtual_machine_name       = "${azurerm_virtual_machine.fundamentals.name}"
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.23"
  auto_upgrade_minor_version = true

  protected_settings = <<PSSETTINGS
      {  
          "Items": {
              "registrationKeyPrivate": "${var.dsc_registration_key}"
          }
      }
  PSSETTINGS

  settings = <<SETTINGS
      {
          "ModulesUrl": "https://github.com/Azure/azure-quickstart-templates/raw/master/dsc-extension-azure-automation-pullserver/UpdateLCMforAAPull.zip",
          "SasToken": "",
          "ConfigurationFunction": "UpdateLCMforAAPull.ps1\\ConfigureLCMforAAPull",
          "Properties": [
              {
                  "Name": "RegistrationKey",
                  "Value": {
                      "UserName": "PLACEHOLDER_DONOTUSE",
                      "Password": "PrivateSettingsRef:registrationKeyPrivate"
                  },
                  "TypeName": "System.Management.Automation.PSCredential"
              },
              {
                  "Name": "RegistrationUrl",
                  "Value": "${var.dsc_registration_url}",
                  "TypeName": "System.String"
              },
              {
                  "Name": "NodeConfigurationName",
                  "Value": "${var.dsc_configuration_name}",
                  "TypeName": "System.String"
              },
              {
                  "Name": "ConfigurationMode",
                  "Value": "ApplyAndAutoCorrect",
                  "TypeName": "System.String"
              },
              {
                  "Name": "ConfigurationModeFrequencyMins",
                  "Value": "15",
                  "TypeName": "System.Int32"
              },
              {
                  "Name": "RefreshFrequencyMins",
                  "Value": "30",
                  "TypeName": "System.Int32"
              },
              {
                  "Name": "RebootNodeIfNeeded",
                  "Value": true,
                  "TypeName": "System.Boolean"
              },
              {
                  "Name": "ActionAfterReboot",
                  "Value": "ContinueConfiguration",
                  "TypeName": "System.String"
              },
              {
                  "Name": "AllowModuleOverwrite",
                  "Value": true,
                  "TypeName": "System.Boolean"
              },
              {
                  "Name": "Timestamp",
                  "Value": "${timestamp()}",
                  "TypeName": "System.String"
              }
          ]
      }
  SETTINGS

  lifecycle {
    ignore_changes = ["settings"]
  }

  tags {
    terraformManaged = "true"
    environment      = "${var.tag_environment}"
  }
}
