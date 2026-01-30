variable "project_name" {
  default = "expense"
}

variable "environment" {
  type = string
  default = "dev"
}

variable "common_tags" {
  type = map
    default = {
      Environment = "dev"
      Project     = "expense"
      CreatedBy   = "terraform"
    }
}

variable "public_key_path" {
  type = string
  default = "~/.ssh/openvpn.pub"
}