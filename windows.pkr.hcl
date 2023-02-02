locals {
  image_name = "windows-2022-x64-server-gh-runner-${formatdate("YYYYMMDDhhmmss", timestamp())}"
}

variable "subscription_id" {
  default = env("AZURE_SUBSCRIPTION_ID")
}

variable "client_id" {
  default = env("AZURE_CLIENT_ID")
}

variable "client_secret" {
  default = env("AZURE_CLIENT_SECRET")
}

variable "sig_resource_group" {}

variable "sig_name" {}

variable "sig_windows_image_name" {}

variable "sig_image_version" {}

variable "regions" {}

source "azure-arm" "windows" {

  # expects Azure auth to be passed in via environment variables, but supports az cli auth as fallback for local use
  use_azure_cli_auth = var.client_id == "" ? true : false
  subscription_id    = var.subscription_id
  client_id          = var.client_id
  client_secret      = var.client_secret
  communicator       = "winrm"

  shared_image_gallery_destination {
    subscription         = var.subscription_id
    resource_group       = var.sig_resource_group
    gallery_name         = var.sig_name
    image_name           = var.sig_windows_image_name
    image_version        = var.sig_image_version
    replication_regions  = var.regions
    storage_account_type = "Standard_LRS"
  }
  managed_image_name                = local.image_name
  managed_image_resource_group_name = var.sig_resource_group

  os_type         = "Windows"
  image_publisher = "MicrosoftWindowsServer"
  image_offer     = "WindowsServer"
  image_sku       = "2022-datacenter"

  winrm_insecure = true
  winrm_timeout  = "5m"
  winrm_use_ssl  = true
  winrm_username = "packer"

  location = "East US"
  vm_size  = "Standard_D2_v2"
}

build {
  sources = ["sources.azure-arm.windows"]

  provisioner "powershell" {
    inline = ["Add-WindowsFeature Web-Server", "while ((Get-Service RdAgent).Status -ne 'Running') { Start-Sleep -s 5 }", "while ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running') { Start-Sleep -s 5 }", "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit", "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } }"]
  }
}
