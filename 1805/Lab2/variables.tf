variable "cidr_block" {
  type = list
  description = "values of CIDRs"
}

variable "allowed_cidr_block" {
  description = "allowed CIDR block"
  type        = string
}

variable "ports" {
  type        = list(number)
}

variable "instance_type" {
  description = "ec2 instance type"
  type        = string
  default = "t2.micro"
}
