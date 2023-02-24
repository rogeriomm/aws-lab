variable "name" {
  description = "File system name"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
  default     = null
}

variable "subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "subnets_cidr_blocks" {
  description = ""
  type        = list(string)
  default     = []
}