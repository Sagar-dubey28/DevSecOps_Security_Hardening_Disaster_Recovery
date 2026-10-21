variable "project_name" { type = string }
variable "vpc_cidr" { type = string }
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "availability_zones" {
  type = list(string)

  validation {
    condition     = length(var.availability_zones) >= max(length(var.public_subnet_cidrs), length(var.private_subnet_cidrs))
    error_message = "Provide an AZ for each subnet index."
  }
}
variable "enable_nat_gateway" {
  type    = bool
  default = true
}
variable "flow_log_retention_days" {
  type    = number
  default = 365
}
variable "tags" {
  type    = map(string)
  default = {}
}
