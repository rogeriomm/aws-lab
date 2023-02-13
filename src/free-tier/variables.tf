variable "profile" {
  description = "AWS Profile"
  type        = string
  default     = "terraform"
}

variable "region" {
  description = "Region for AWS resources"
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Project name"
  type        = string
  default     = "free-tier"
}

variable "ec2_ssh_key_name" {
  description = "The SSH Key Name"
  type        = string
  default     = "free-tier-ec2-key"
}

variable "ec2_ssh_public_key_path" {
  description = "The local path to the SSH Public Key"
  type        = string
  default     = "./provision/access/free-tier-ec2-key.pub"
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
