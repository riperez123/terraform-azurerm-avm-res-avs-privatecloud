variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "name" {
  type        = string
  description = "The name to use when creating the avs sddc private cloud."
  nullable    = false
}

variable "location" {
  type        = string
  description = "The Azure region where this and supporting resources should be deployed.  Defaults to the Resource Groups location if undefined."
  default     = null
}

variable "sku_name" {
  type        = string
  description = "The sku value for the AVS SDDC management cluster nodes. Valid values are av20, av36, av36t, av36pt, av52, av64."
}

variable "avs_network_cidr" {
  type        = string
  description = "The full /22 or larger network CIDR summary for the private cloud managed components. This range should not intersect with any IP allocations that will be connected or visible to the private cloud."
}

variable "tags" {
  type        = map(any)
  default     = {}
  description = "Map of tags to be assigned to this resource"
}

variable "internet_enabled" {
  type        = bool
  description = "Configure the internet SNAT option to be on or off. Defaults to off."
  default     = false
}

variable "management_cluster_size" {
  type        = number
  description = "The number of nodes to include in the management cluster. The minimum value is 3 and the current maximum is 16."
  default     = 3
}

variable "vcenter_password" {
  type        = string
  description = "The password value to use for the cloudadmin account password in the local domain in vcenter. If this is left as null a random password will be generated for the deployment"
  default     = null
  sensitive   = true
}

variable "nsxt_password" {
  type        = string
  description = "The password value to use for the cloudadmin account password in the local domain in nsxt. If this is left as null a random password will be generated for the deployment"
  default     = null
  sensitive   = true
}

variable "hcx_enabled" {
  type        = bool
  description = "Enable the HCX addon toggle value"
  default     = false
}

variable "hcx_license_type" {
  type        = string
  description = "Describes which HCX license option to use.  Valid values are Advanced or Enterprise."
  default     = "Enterprise"
}

variable "hcx_key_names" {
  type        = list(string)
  description = "list of key names to use when generating hcx site activation keys. Requires HCX add_on to be enabled."
  default     = []
}

variable "srm_enabled" {
  type        = bool
  description = "Enable the SRM addon toggle value"
  default     = false
}

variable "srm_license_key" {
  type        = string
  description = "The license key to use for the SRM installation"
  default     = null
}

variable "vr_enabled" {
  type        = bool
  description = "Enable the Vsphere Replication (VR) addon toggle value"
  default     = false
}

variable "vrs_count" {
  type        = number
  description = "The total number of vsphere replication servers to deploy"
  default     = null
}

variable "arc_enabled" {
  type        = bool
  description = "Enable the ARC addon toggle value"
  default     = false
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = optional(string)
    condition                              = optional(string)
    condition_version                      = optional(string)
    description                            = optional(string)
    skip_service_principal_aad_check       = optional(bool, true)
    delegated_managed_identity_resource_id = optional(string)
    }
  ))
  default  = {}
  nullable = false

  description = <<ROLE_ASSIGNMENTS
  A list of role definitions and scopes to be assigned as part of this resources implementation.  
  list(object({

    - `principal_id`                               = (optional) - The ID of the Principal (User, Group or Service Principal) to assign the Role Definition to. Changing this forces a new resource to be created.
    - `role_definition_id_or_name`                 = (Optional) - The Scoped-ID of the Role Definition or the built-in role name. Changing this forces a new resource to be created. Conflicts with role_definition_name 
    - `condition`                                  = (Optional) - The condition that limits the resources that the role can be assigned to. Changing this forces a new resource to be created.
    - `condition_version`                          = (Optional) - The version of the condition. Possible values are 1.0 or 2.0. Changing this forces a new resource to be created.
    - `description`                                = (Optional) - The description for this Role Assignment. Changing this forces a new resource to be created.
    - `skip_service_principal_aad_check`           = (Optional) - If the principal_id is a newly provisioned Service Principal set this value to true to skip the Azure Active Directory check which may fail due to replication lag. This argument is only valid if the principal_id is a Service Principal identity. Defaults to true.
    - `delegated_managed_identity_resource_id`     = (Optional) - The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created.  

  }))

  Example Inputs:

  ```terraform
    role_assignments = {
      role_assignment_1 = {
        role_definition_id_or_name                 = "Contributor"
        principal_id                               = data.azuread_client_config.current.object_id
        description                                = "Example for assigning a role to an existing principal for the Private Cloud scope"        
      }
    }
  ```
  ROLE_ASSIGNMENTS
}

#Diagnostic Settings
variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  nullable    = false
  description = <<DIAGNOSTIC_SETTINGS
  This map object is used to define the diagnostic settings on the virtual machine.  This functionality does not implement the diagnostic settings extension, but instead can be used to configure sending the vm metrics to one of the standard targets.
  map(object({
    
    - `name`                                     = (required) - Name to use for the Diagnostic setting configuration.  Changing this creates a new resource
    - `log_categories_and_groups`                = (Optional) - List of strings used to define log categories and groups. Currently not valid for the VM resource
    - `log_groups`                               = (Optional) - A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`
    - `metric_categories`                        = (Optional) - List of strings used to define metric categories. Currently only AllMetrics is valid
    - `log_analytics_destination_type`           = (Optional) - Valid values are null, AzureDiagnostics, and Dedicated.  Defaults to Dedicated
    - `workspace_resource_id`                    = (Optional) - The Log Analytics Workspace Azure Resource ID when sending logs or metrics to a Log Analytics Workspace
    - `storage_account_resource_id`              = (Optional) - The Storage Account Azure Resource ID when sending logs or metrics to a Storage Account
    - `event_hub_authorization_rule_resource_id` = (Optional) - The Event Hub Namespace Authorization Rule Resource ID when sending logs or metrics to an Event Hub Namespace
    - `event_hub_name`                           = (Optional) - The Event Hub name when sending logs or metrics to an Event Hub
    - `marketplace_partner_resource_id`          = (Optional) - The marketplace partner solution Azure Resource ID when sending logs or metrics to a partner integration

  }))

  ```terraform
  Example Input:
    diagnostic_settings = {
      nic_diags = {
        name                  = module.naming.monitor_diagnostic_setting.name_unique
        workspace_resource_id = azurerm_log_analytics_workspace.this_workspace.id
        metric_categories     = ["AllMetrics"]
      }
    }
  ```
  DIAGNOSTIC_SETTINGS
}

#resource doesn't support user-assigned managed identities.
variable "managed_identities" {
  type = object({
    system_assigned = optional(bool, false)
  })
  default     = {}
  nullable    = false
  description = "This value toggles the system managed identity to on for use with customer managed keys. User Managed identities are currently unsupported for this resource. Defaults to false."
}

variable "lock" {
  type = object({
    name = optional(string, null)
    kind = optional(string, "None")
  })
  description = <<LOCK
    "The lock level to apply to this virtual machine and all of it's child resources. The default value is none. Possible values are `None`, `CanNotDelete`, and `ReadOnly`. Set the lock value on child resource values explicitly to override any inherited locks." 

    Example Inputs:
    ```terraform
    lock = {
      name = "lock-{resourcename}" # optional
      type = "CanNotDelete" 
    }
    ```
    LOCK
  default     = {}
  nullable    = false
  validation {
    condition     = contains(["CanNotDelete", "ReadOnly", "None"], var.lock.kind)
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}

variable "customer_managed_key" {
  type = object({
    key_vault_resource_id = optional(string, null)
    key_name              = optional(string, null)
    key_version           = optional(string, null)
  })
  default     = {}
  nullable    = false
  description = <<CUSTOMER_MANAGED_KEY
    This object defines the customer managed key details to use when encrypting the VSAN datastore. 
   
    - `key_vault_resource_id` = (Required) - The full Azure resource ID of the key vault where the encryption key will be sourced from
    - `key_name`              = (Required) - The name for the encryption key
    - `key_version`           = (Optional) - The key version value for the encryption key. 

    Example Inputs:
    ```terraform
      {
        key_vault_resource_id = azurerm_key_vault.example.id
        key_name              = azurerm_key_vault_key.example.name
        key_version           = azurerm_key_vault_key.example.version
      }
    ```
    CUSTOMER_MANAGED_KEY
}

variable "clusters" {
  type = map(object({
    cluster_node_count = number
    sku_name           = string
  }))
  default     = {}
  nullable    = false
  description = <<CLUSTERS
    This object describes additional clusters in the private cloud in addition to the management cluster. The map key will be used as the cluster name
    map(object({

      - `cluster_node_count` = (required) - Integer number of nodes to include in this cluster between 3 and 16
      - `sku_name`           = (required) - String for the sku type to use for the cluster nodes. Changing this forces a new cluster to be created
      
    ))}
    Example Input:
    ```terraform
       cluster1 = {
        cluster_node_count = 3
        sku_name           = "av36p"
       }
    ```
  CLUSTERS
}

variable "expressroute_auth_keys" {
  type        = set(string)
  default     = []
  description = "This set of strings defines one or more names to creating new expressroute authorization keys for the private cloud"
}

variable "primary_zone" {
  type        = number
  default     = null
  description = "This value represents the zone for deployment in a standard deployment or the primary zone in a stretch cluster deployment. Defaults to null to let Azure select the zone"
}

variable "secondary_zone" {
  type        = number
  default     = null
  description = "This value represents the secondary zone in a stretch cluster deployment."
}

variable "enable_stretch_cluster" {
  type        = bool
  default     = false
  description = "Set this value to true if deploying an AVS stretch cluster."
}

variable "vcenter_identity_sources" {
  type = map(object({
    alias            = string
    base_group_dn    = string
    base_user_dn     = string
    domain           = string
    group_name       = optional(string, null)
    name             = string
    primary_server   = string
    secondary_server = optional(string, null)
    ssl              = optional(string, "Enabled")
    timeout          = optional(string, "10m")
  }))
  default     = {}
  nullable    = false
  description = <<VCENTER_IDENTITY_SOURCES
  A map of objects representing a list of 0-2 identity sources for configuring LDAP or LDAPs on the private cloud. The map key will be used as the name value for the identity source.
    map(object({

      - `alias`             = (Required) - The domains NETBIOS name
      - `base_group_dn`     = (Required) - The base distinguished name for groups
      - `base_user_dn`      = (Required) - The base distinguished name for users
      - `domain`            = (Required) - The fully qualified domain name for the identity source
      - `group_name`        = (Optional) - The name of the LDAP group that will be added to the cloudadmins role
      - `name`              = (Required) - The name to give the identity source
      - `primary_server`    = (Required) - The URI of the primary server. (Ex: ldaps://server.domain.local:636)
      - `secondary_server`  = (Optional) - The URI of the secondary server. (Ex: ldaps://server.domain.local:636)
      - `ssl`               = (Optional) - Determines if ldap is configured to use ssl. Default to Enabled, valid values are "Enabled" and "Disabled"
      - 'timeout'           = (Optional) - The implementation timeout value.  Defaults to 10 minutes.

    }))

    Example Input:
    ```terraform
      {
        test.local = {
          alias                   = "test.local"
          base_group_dn           = "dc=test,dc=local"
          base_user_dn            = "dc=test,dc=local"
          domain                  = "test.local"
          name                    = "test.local"
          primary_server          = "ldaps://dc01.testdomain.local:636"
          secondary_server        = "ldaps://dc02.testdomain.local:636"
          ssl                     = "Enabled"
        }
      }
  ```
  VCENTER_IDENTITY_SOURCES
}

variable "ldap_user" {
  type        = string
  description = "The username for the domain user the vcenter will use to query LDAP(s)"
  default     = null
}

variable "ldap_user_password" {
  type        = string
  description = "Password to use for the domain user the vcenter will use to query LDAP(s)"
  sensitive   = true
  default     = null
}

variable "global_reach_connections" {
  type = map(object({
    authorization_key                     = string
    peer_expressroute_circuit_resource_id = string
  }))
  default     = {}
  nullable    = false
  description = <<GLOBAL_REACH_CONNECTIONS
    Map of string objects describing one or more global reach connections to be configured by the private cloud. The map key will be used for the connection name.
    map(object({

      - `authorization_key`                     = (Required) - The authorization key from the peer expressroute 
      - `peer_expressroute_circuit_resource_id` = (Optional) - Identifier of the ExpressRoute Circuit to peer within the global reach connection
      
      })
    )

  Example Input:
    ```terraform
    {
      gr_region_1 = {
        authorization_key                     = "<auth key value>"
        peer_expressroute_circuit_resource_id = "Azure Resource ID for the peer expressRoute circuit"'
      }
    }
    ```
  GLOBAL_REACH_CONNECTIONS
}

variable "avs_interconnect_connections" {
  type = map(object({
    linked_private_cloud_resource_id = string
  }))
  default     = {}
  nullable    = false
  description = <<INTERCONNECT
    Map of string objects describing one or more private cloud interconnect connections for private clouds in the same region.  The map key will be used for the connection name.
    map(object({

      - `linked_private_cloud_resource_id` = (Required) - The resource ID of the private cloud on the other side of the interconnect. Must be in the same region.

      })
    )

  Example Input:
    ```terraform
    {
      interconnect_sddc_1 = {
        linked_private_cloud_resource_id = "<SDDC resource ID>"
      }
    }
    ```
  INTERCONNECT
}

variable "expressroute_connections" {
  type = map(object({
    vwan_hub_connection              = optional(bool, false)
    expressroute_gateway_resource_id = string
    authorization_key_name           = optional(string, null)
    fast_path_enabled                = optional(bool, false)
    routing_weight                   = optional(number, 0)
    enable_internet_security         = optional(bool, false)
    routing = optional(map(object({
      associated_route_table_resource_id = optional(string, null)
      inbound_route_map_resource_id      = optional(string, null)
      outbound_route_map_resource_id     = optional(string, null)
      propagated_route_table = optional(object({
        labels = optional(list(string), [])
        ids    = optional(list(string), [])
      }), {})
    })), {})
  }))
  default     = {}
  nullable    = false
  description = <<EXPRESSROUTE_CONNECTIONS
    Map of string objects describing one or more global reach connections to be configured by the private cloud. The map key will be used for the connection name.
    map(object({

    - `vwan_hub_connection`                  = (Optional) - Set this to true if making a connection to a VWAN hub.  Leave as false if connecting to an ExpressRoute gateway in a virtual network hub.
    - `expressroute_gateway_resource_id`     = (Required) - The Azure Resource ID for the ExpressRoute gateway where the connection will be made.
    - `authorization_key_name`               = (Optional) - The authorization key name that should be used from the auth key map. If no key is provided a name will be generated from the map key.
    - `fast_path_enabled`                    = (Optional) - Should fast path gateway bypass be enabled. There are sku and cost considerations to be aware of when enabling fast path. Defaults to false
    - `routing_weight`                       = (Optional) - The routing weight value to use for this connection.  Defaults to 0.
    - `enable_internet_security`             = (Optional) - Set this to true if connecting to a secure VWAN hub and you want the hub NVA to publish a default route to AVS.
    - `routing`                              =  Optional( map ( object({
      - `associated_route_table_resource_id` = (Optional) - The Azure Resource ID of the Virtual Hub Route Table associated with this Express Route Connection.
      - `inbound_route_map_resource_id`      = (Optional) - The Azure Resource ID Of the Route Map associated with this Express Route Connection for inbound learned routes
      - `outbound_route_map_resource_id`     = (Optional) - The Azure Resource ID Of the Route Map associated with this Express Route Connection for outbound advertised routes
      - `propagated_route_table` = object({ 
        - `labels` = (Optional) - The list of labels for route tables where the routes will be propagated to
        - `ids`    = (Optional) - The list of Azure Resource IDs for route tables where the routes will be propagated to

      })
    })), null)
  }))

  Example Input:
    ```terraform
    {
      exr_region_1 = {
        expressroute_gateway_resource_id                     = "<expressRoute Gateway Resource ID>"
        peer_expressroute_circuit_resource_id = "Azure Resource ID for the peer expressRoute circuit"'
      }
    }
    ```
  EXPRESSROUTE_CONNECTIONS
}

variable "dns_forwarder_zones" {
  type = map(object({
    display_name               = string
    dns_server_ips             = list(string)
    domain_names               = list(string)
    source_ip                  = optional(string, "")
    add_to_default_dns_service = optional(bool, false)
  }))
  default     = {}
  nullable    = false
  description = <<DNS_FORWARDER_ZONES
    Map of string objects describing one or more dns forwarder zones for NSX within the private cloud. Up to 5 additional forwarder zone can be configured. 
    This is primarily useful for identity source configurations or in cases where NSX DHCP is providing DNS configurations.
    map(object({

    - `display_name`               = (Required) - The display name for the new forwarder zone being created.  Commonly this aligns with the domain name.
    - `dns_server_ips`             = (Required) - A list of up to 3 IP addresses where zone traffic will be forwarded.
    - `domain_names`               = (Required) - A list of domain names that will be forwarded as part of this zone.
    - `source_ip`                  = (Optional) - Source IP of the DNS zone.  Defaults to an empty string.  
    - 'add_to_default_dns_service' = (Optional) - Set to try to associate this zone with the default DNS service.  Up to 5 zones can be linked.

  }))

  Example Input:
    ```terraform
    {
      test_local = {
        display_name               = local.test_domain_name
        dns_server_ips             = ["10.0.1.53","10.0.2.53"]
        domain_names               = ["test.local"]
        add_to_default_dns_service = true
      }
    }
    ```
  DNS_FORWARDER_ZONES

}

variable "dhcp_configuration" {
  type = map(object({
    display_name           = string
    dhcp_type              = string
    relay_server_addresses = optional(list(string), [])
    server_lease_time      = optional(number, 86400)
    server_address         = optional(string, null)
  }))
  default     = {}
  nullable    = false
  description = <<DHCP
    This map object describes the DHCP configuration to use for the private cloud. It can remain unconfigured or define a RELAY or SERVER based configuration. Defaults to unconfigured. 
    This allows for new segments to define DHCP ranges as part of their definition. Only one DHCP configuration is allowed.
    map(object({

    - `display_name`           = (Required) - The display name for the dhcp configuration being created
    - `dhcp_type`              = (Required) - The type for the DHCP server configuration.  Valid types are RELAY or SERVER. RELAY defines a relay configuration pointing to your existing DHCP servers. SERVER configures NSX-T to act as the DHCP server.
    - `relay_server_addresses` = (Optional) - A list of existing DHCP server ip addresses from 1 to 3 servers.  Required when type is set to RELAY.    
    - `server_lease_time`      = (Optional) - The lease time in seconds for the DHCP server. Defaults to 84600 seconds.(24 hours) Only valid for SERVER configurations
    - `server_address`         = (Optional) - The CIDR range that NSX-T will use for the DHCP Server.

  }))

  Example Input:
    ```terraform
    #RELAY example
    relay_config = {
      display_name           = "relay_example"
      dhcp_type              = "RELAY"
      relay_server_addresses = ["10.0.1.50", "10.0.2.50"]      
    }

    #SERVER example
    server_config = {
      display_name      = "server_example"
      dhcp_type         = "SERVER"
      server_lease_time = 14400
      server_address    = "10.1.0.1/24"
    }
    ```
  DHCP
}

variable "segments" {
  type = map(object({
    display_name      = string
    gateway_address   = string
    dhcp_ranges       = optional(list(string), [])
    connected_gateway = optional(string, null)
  }))
  default     = {}
  nullable    = false
  description = <<SEGMENTS
    This map object describes the additional segments to configure on the private cloud. It can remain unconfigured or define one or more new network segments. Defaults to unconfigured. 
    If the connected_gateway value is left undefined, the configuration will default to using the default T1 gateway provisioned as part of the managed service.
    map(object({

    - `display_name`       = (Required) - The display name for the dhcp configuration being created
    - `gateway_address`    = (Required) - The CIDR range to use for the segment
    - `dhcp_ranges`        = (Optional) - One or more ranges of IP addresses or CIDR blocks entered as a list of string
    - `connected_gateway`  = (Optional) - The name of the T1 gateway to connect this segment to.  Defaults to the managed t1 gateway if left unconfigured.

  }))

  Example Input:
    ```terraform
    segment_1 = {
      display_name    = "segment_1"
      gateway_address = "10.20.0.1/24"
      dhcp_ranges     = ["10.20.0.5-10.20.0.100"]      
    }
    segment_2 = {
      display_name    = "segment_2"
      gateway_address = "10.30.0.1/24"
      dhcp_ranges     = ["10.30.0.0/24"]
    }
    ```
  SEGMENTS
}



variable "netapp_files_datastores" {
  type = map(object({
    netapp_volume_resource_id = string
    cluster_names             = set(string)
  }))
  default     = {}
  nullable    = false
  description = <<NETAPP_FILES_ATTACHMENTS
    This map of objects describes one or more netapp volume attachments.  The map key will be used for the datastore name and should be unique. 
    map(object({

      - `netapp_volume_resource_id` = (required) - The azure resource ID for the Azure Netapp Files volume being attached to the cluster nodes.
      - `cluster_names`             = (required) - A set of cluster name(s) where this volume should be attached

    }))

    Example Input:
    ```terraform
      anf_datastore_cluster1 = {
        netapp_volume_resource_id = azurerm_netapp_volume.test.id
        cluster_names             = ["Cluster-1"]
      }
    ```
  NETAPP_FILES_ATTACHMENTS
}

variable "internet_inbound_public_ips" {
  type = map(object({
    number_of_ip_addresses = number
  }))
  default     = {}
  nullable    = false
  description = <<PUBLIC_IPS
    This map object that describes the public IP configuration. Configure this value in the event you need direct inbound access to the private cloud from the internet. The code uses the map key as the display name for each configuration.
    map(object({

      - `number_of_ip_addresses` = (required) - The number of IP addresses to assign to this private cloud.

    }))

    Example Input:
    ```terraform
      public_ip_config = {
        display_name = "public_ip_configuration"
        number_of_ip_addresses = 1
      }
    ```
  PUBLIC_IPS
}