terraform {
  required_version = "~>1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.13, != 1.13.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.10"
    }
  }
}

# tflint-ignore: terraform_module_provider_declaration, terraform_output_separate, terraform_variable_separate
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {
  enable_hcl_output_for_data_source = true
}

locals {
  vm_sku = "Standard_D2_v4"
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "= 0.4.0"
}

module "regions" {
  source  = "Azure/regions/azurerm"
  version = "= 0.4.0"
}

data "azurerm_client_config" "current" {}

module "generate_deployment_region" {
  #source               = "../../modules/generate_deployment_region"
  source               = "git::https://github.com/Azure/terraform-azurerm-avm-res-avs-privatecloud.git//modules/generate_deployment_region"
  total_quota_required = 3
}

resource "local_file" "region_sku_cache" {
  filename = "${path.module}/region_cache.cache"
  content  = jsonencode(module.generate_deployment_region.deployment_region)

  lifecycle {
    ignore_changes = [content]
  }
}

resource "azurerm_resource_group" "this" {
  location = jsondecode(local_file.region_sku_cache.content).name
  name     = module.naming.resource_group.name_unique

  lifecycle {
    ignore_changes = [tags, location]
  }
}

resource "azurerm_virtual_wan" "vwan" {
  location                       = azurerm_resource_group.this.location
  name                           = module.naming.virtual_wan.name_unique
  resource_group_name            = azurerm_resource_group.this.name
  allow_branch_to_branch_traffic = true
  type                           = "Standard"
}

resource "azurerm_virtual_hub" "vwan_hub" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.virtual_wan.name_unique}-avs-hub"
  resource_group_name = azurerm_resource_group.this.name
  address_prefix      = "10.200.0.0/16"
  virtual_wan_id      = azurerm_virtual_wan.vwan.id
}

resource "azurerm_express_route_gateway" "vwan_express_route_gateway" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.express_route_gateway.name_unique
  resource_group_name = azurerm_resource_group.this.name
  scale_units         = 2
  virtual_hub_id      = azurerm_virtual_hub.vwan_hub.id
}


resource "azurerm_public_ip" "nat_gateway" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.nat_gateway.name_unique}-pip"
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "this_nat_gateway" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.nat_gateway.name_unique
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "this_nat_gateway" {
  nat_gateway_id       = azurerm_nat_gateway.this_nat_gateway.id
  public_ip_address_id = azurerm_public_ip.nat_gateway.id
}

module "vm_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "=0.1.3"

  resource_group_name           = azurerm_resource_group.this.name
  virtual_network_address_space = ["10.100.0.0/16"]
  vnet_name                     = "VMVnet"
  vnet_location                 = azurerm_resource_group.this.location

  subnets = {
    VMSubnet = {
      address_prefixes = ["10.100.1.0/24"]
      nat_gateway = {
        id = azurerm_nat_gateway.this_nat_gateway.id
      }
    }
    AzureBastionSubnet = {
      address_prefixes = ["10.100.2.0/24"]
    }
  }
}

resource "azurerm_virtual_hub_connection" "vm_vnet_connection" {
  name                      = "${module.naming.virtual_wan.name_unique}-avs-hub-to-vmvnet"
  remote_virtual_network_id = module.vm_vnet.vnet-resource.id
  virtual_hub_id            = azurerm_virtual_hub.vwan_hub.id
}

resource "azurerm_log_analytics_workspace" "this_workspace" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
  retention_in_days   = 30
  sku                 = "PerGB2018"
}

module "avm_res_keyvault_vault" {
  source                 = "Azure/avm-res-keyvault-vault/azurerm"
  version                = "0.5.1"
  tenant_id              = data.azurerm_client_config.current.tenant_id
  name                   = module.naming.key_vault.name_unique
  resource_group_name    = azurerm_resource_group.this.name
  location               = azurerm_resource_group.this.location
  enabled_for_deployment = true
  network_acls = {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  role_assignments = {
    deployment_user_secrets = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }

  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }
}

module "test_private_cloud" {
  source = "../../"
  # source             = "Azure/avm-res-avs-privatecloud/azurerm"
  # version            = "=0.5.0"

  enable_telemetry           = var.enable_telemetry
  resource_group_name        = azurerm_resource_group.this.name
  location                   = azurerm_resource_group.this.location
  resource_group_resource_id = azurerm_resource_group.this.id
  name                       = "avs-sddc-${substr(module.naming.unique-seed, 0, 4)}"
  sku_name                   = jsondecode(local_file.region_sku_cache.content).sku
  avs_network_cidr           = "10.0.0.0/22"
  internet_enabled           = false
  management_cluster_size    = 3

  addons = {
    HCX = {
      hcx_key_names    = ["example_key_1", "example_key_2"]
      hcx_license_type = "Enterprise"
    }
  }

  diagnostic_settings = {
    avs_diags = {
      name                  = module.naming.monitor_diagnostic_setting.name_unique
      workspace_resource_id = azurerm_log_analytics_workspace.this_workspace.id
      metric_categories     = ["AllMetrics"]
      log_groups            = ["allLogs"]
    }
  }

  expressroute_connections = {
    default = {
      vwan_hub_connection              = true
      expressroute_gateway_resource_id = azurerm_express_route_gateway.vwan_express_route_gateway.id
      authorization_key_name           = "test_auth_key"
    }
  }

  tags = {
    scenario = "avs_default_vnet"
  }
}

module "create_jump_vm" {
  #source = "../../modules/create_jump_vm"
  source = "git::https://github.com/Azure/terraform-azurerm-avm-res-avs-privatecloud.git//modules/create_jump_vm"


  resource_group_name        = azurerm_resource_group.this.name
  resource_group_location    = azurerm_resource_group.this.location
  vm_name                    = "jump-${module.naming.virtual_machine.name_unique}"
  key_vault_resource_id      = module.avm_res_keyvault_vault.resource.id
  create_bastion             = true
  bastion_name               = module.naming.bastion_host.name_unique
  bastion_pip_name           = "${module.naming.bastion_host.name_unique}-pip"
  bastion_subnet_resource_id = module.vm_vnet.subnets["AzureBastionSubnet"].id
  vm_subnet_resource_id      = module.vm_vnet.subnets["VMSubnet"].id
  vm_sku                     = local.vm_sku

  depends_on = [module.avm_res_keyvault_vault, module.vm_vnet, azurerm_nat_gateway.this_nat_gateway]
}
