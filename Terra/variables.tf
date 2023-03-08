variable location {
  description = "Location of my resource"
  type        = string
  default     = "West Europe"
}

# variable "sevenZip" {
#   description = "Path to 7z"
#   type        = string
#   default     = "C:/Programs/7z.exe"
# }

variable incomeHttpFunction {
  description = "Name of IncomeHttp function. Used in path, archName etc"
  default = "IncomeHttpFunction"
}

variable pathPublishIncomeHttFunction {
  description = "Path to IncomeHttp publish"
  type        = string
  default     = "../IncomeHttpFunction/bin/Release/net6.0/publish/"
}

variable zipPackageIncomeHttpFunction {
  description = "Name of arch wich contains IncomeHttpFunction"
  type        = string
  default     = "IncomeHttpFunction.zip"
}
