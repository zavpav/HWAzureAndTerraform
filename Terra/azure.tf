terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "=3.46.0"
    }
  }
}

provider azurerm {
    features {
    }
}



resource azurerm_resource_group pzaz {
  name     = "pzaz"
  location = var.location
}

# # а нужен ли он мне тут?
# resource "azurerm_application_insights" "pzaz_application_insights" {
#   name                = "pzaz_application_insights"
#   location            = var.location
#   resource_group_name = azurerm_resource_group.pzaz.names
#   application_type    = "web"
#   retention_in_days   = 30
# }

locals {
  rebuild_income_http_trigger_sha = sha1(join("", tolist([
        for f in fileset("../", "**"):
            filesha1("../${f}") 
                if length(regexall("(/bin/|/obj/|/\\.)", lower(f))) == 0
                    && length(regexall(lower(var.incomeHttpFunction), lower(f))) != 0 
                    && !startswith(f, ".") 
        ]))) #"none" #sha1(join("", [for f in fileset("../", "**") : filesha1(f)])) #"${timestamp()}" #requirements_md5 = "${filemd5("${path.module}/functions/requirements.txt")}"
}

resource null_resource clear_income_http {
    triggers = {
        always_run = "${local.rebuild_income_http_trigger_sha}"
    }
    provisioner "local-exec" {
        command = "del ${var.zipPackageIncomeHttpFunction}"
        interpreter = ["PowerShell", "-Command"]
        on_failure = continue
    }
    
}

resource null_resource build_income_http {
    triggers = {
        always_run = "${local.rebuild_income_http_trigger_sha}"
    }
    provisioner "local-exec" {
        command = "dotnet publish --configuration Release ../AzureTest.sln"
        interpreter = ["PowerShell", "-Command"]
    }

  depends_on = [null_resource.clear_income_http]
}

# resource "null_resource" "archF1" {
#     triggers = {
#         always_run = "${timestamp()}"
#     }
#     provisioner "local-exec" {
#         command = "${var.sevenZip} a ${var.azureFunctionBinName} ${var.pathToFunctionBin}"
#         interpreter = ["PowerShell", "-Command"]
#     }
#     depends_on = [null_resource.buildF1]
# }

data archive_file arch_income_http{
  type        = "zip"
  source_dir  = "${var.pathPublishIncomeHttFunction}"
  output_path = "${var.zipPackageIncomeHttpFunction}"

  depends_on = [null_resource.build_income_http, null_resource.clear_income_http]
}



# аккаунт для хранения бинарников
resource "azurerm_storage_account" "pzaz_storage_account_f_one" {
  name                     = "pzazstrgacc1q"
  resource_group_name      = azurerm_resource_group.pzaz.name
  location                 = var.location
  #   account_kind             = "BlobStorage"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "pzaz storage account for my Azure Functions"
  }
}

# каталог для хранения бинарников для F1
resource "azurerm_storage_container" "pzaz_function_f_one" {
  name                 = "function-f-one-releases"
  storage_account_name = azurerm_storage_account.pzaz_storage_account_f_one.name
  container_access_type = "private"
}

resource azurerm_storage_blob storage_blob_function_f1 {
  name                   = "functions-${substr(data.archive_file.arch_income_http.output_md5, 0, 6)}.zip"
  storage_account_name   = azurerm_storage_account.pzaz_storage_account_f_one.name
  storage_container_name = azurerm_storage_container.pzaz_function_f_one.name
  type                   = "Block"
  source                 = data.archive_file.arch_income_http.output_path
  # triggers = {
  #   always_run = "${local.rebuild_income_http_trigger_sha}" # recreate if rebuild
  # }

}

resource "azurerm_service_plan" "pzaz_service_plan" {
    name = "pzaz_function_computation"
    resource_group_name = azurerm_resource_group.pzaz.name
    location = var.location
    os_type = "Windows"
    sku_name = "Y1" # dynamic Consumption for azure functions
}



# use azurerm_role_assignment and azurerm_storage_blob.storage_blob_function_f1.url
# or azurerm_storage_account_sas and generate havy url
#WEBSITE_RUN_FROM_PACKAGE = "https://${azurerm_storage_account.pzaz_storage_account_f_one.name}.blob.core.windows.net/${azurerm_storage_container.pzaz_function_f_one.name}/${azurerm_storage_blob.storage_blob_function_f1.name}${data.azurerm_storage_account_sas.sas_f_one.sas}"
# data "azurerm_storage_account_sas" "sas_f_one" {
#   connection_string = azurerm_storage_account.pzaz_storage_account_f_one.primary_connection_string
#   https_only        = false
#   signed_version    = "2017-07-29"

#   resource_types {
#     service   = false
#     container = false
#     object    = true
#   }

#   services {
#     blob  = true
#     queue = false
#     table = false
#     file  = false
#   }

#   start  = "2018-03-21"
#   expiry = "2028-03-21"

#   permissions {
#     read    = true
#     write   = false
#     delete  = false
#     list    = false
#     add     = false
#     create  = false
#     update  = false
#     process = false
#     tag     = false
#     filter  = false
#   }
# }
# output "azure_binary_file" {
#     value = nonsensitive("https://${azurerm_storage_account.pzaz_storage_account_f_one.name}.blob.core.windows.net/${azurerm_storage_container.pzaz_function_f_one.name}/${azurerm_storage_blob.storage_blob_function_f1.name}${data.azurerm_storage_account_sas.sas_f_one.sas}")
# #    sensitive = true
# }

# use azurerm_role_assignment and azurerm_storage_blob.storage_blob_function_f1.url
# or azurerm_storage_account_sas and generate havy url
resource "azurerm_role_assignment" "role_assignment_storage" {
  scope                            = azurerm_storage_account.pzaz_storage_account_f_one.id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = azurerm_windows_function_app.pzaz_function_f_one.identity.0.principal_id
}



resource "azurerm_windows_function_app" "pzaz_function_f_one" {
  name                       = "pzaz-function-f-one"
  resource_group_name        = azurerm_resource_group.pzaz.name
  location                   = var.location
  
  storage_account_name       = azurerm_storage_account.pzaz_storage_account_f_one.name
  storage_account_access_key = azurerm_storage_account.pzaz_storage_account_f_one.primary_access_key

  service_plan_id            = azurerm_service_plan.pzaz_service_plan.id
  functions_extension_version = "~4"

  enabled = true
  # https_only = true

  identity { 
    type = "SystemAssigned" 
  }

  app_settings = {
    WEBSITE_RUN_FROM_PACKAGE = azurerm_storage_blob.storage_blob_function_f1.url
  }

  site_config {
    #     dynamic "ip_restriction" {
    #   for_each = var.allowed_ip_addresses
    #   content {
    #     ip_address = ip_restriction.value
    #   }
    # }

    application_stack {
       dotnet_version = "v6.0"
    }
    always_on = false
  #  application_insights_key = azurerm_application_insights.pzaz_application_insights.instrumentation_key
    
  }
}


output "function_app_default_hostname" {
  value = azurerm_windows_function_app.pzaz_function_f_one.default_hostname
  description = "Deployed function app hostname"
}

output "azure_function_f1_url" {
  value = azurerm_storage_blob.storage_blob_function_f1.url
  description = "Storage of function"
}

output resource_group {
  value = {
      name = azurerm_resource_group.pzaz.name,
      location =azurerm_resource_group.pzaz.location
  }  
}

output "income_http_blob_name" {
   value = azurerm_storage_blob.storage_blob_function_f1.name
}
