variable "project_name" {
  default = "expense"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "zone_name" {
  default = "surya-devops.site"
}

variable "common_tags" {
  type = map(any)
  default = {
    Environment = "dev"
    Project     = "expense"
    CreatedBy   = "terraform"
    Component   = "cdn"
  }
}