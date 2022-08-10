variable "image_tag_mutability" {
  default = "MUTABLE"
}

variable "vpc_cidr_block" {
  type = string
  description = "cidr block to create vpc with"
}

variable "public_subnet_cidr_blocks" {
  type = list(string)
  description = "list of cidr blocks to create public subnet with"
}

variable "env" {
  type        = string
  description = "name of the env i.e. dev/prod/uat/test"
}

variable "private_subnet_cidr_blocks" {
  type = list(string)
  description = "list of cidr blocks to create public subnet with"
}

variable "sgsid_ecs_host" {
  type = string
}


