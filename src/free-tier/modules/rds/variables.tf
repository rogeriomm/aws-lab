variable "name" {
  description = "Prefix name"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "VPC id"
  type        = string
  default     = null
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block"
  type        = string
  default     = null
}

variable "database_subnet_group" {
  description = "Database subnet group"
  type        = string
  default     = null
}

variable "database_subnets" {
  description = "A list of database subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "major_version" {
  type        = map(string)
  description = "Map of Postgres versions"

  default = {
    # 10
    "10.1" = "10"
    "10.3" = "10"
    "10.4" = "10"
    "10.5" = "10"
    "10.6" = "10"

    # 11
    "11.1" = "11"
    "11.2" = "11"
    "11.4" = "11"

    # 14
    "14.6" = "14"
  }
}

variable "engine_version" {
  description = ""
  type        = string
  default     = "14.6"
}

