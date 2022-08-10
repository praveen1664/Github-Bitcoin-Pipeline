variable "image_tag_mutability" {
  default = "MUTABLE"
}

variable "availability_zone" {
  default = "us-east-1a"
}

variable "availability_zone2" {
  default = "us-east-1b"
}

variable "env" {
  type        = string
  description = "name of the env i.e. dev/prod/uat/test"
}

variable "ecr_name" {
  type        = string
  description = "Name of the ECR repo"
  default = "bitcoinecr"
}
variable "public_subnet_cidr_blocks" {
  type = list(string)
  description = "list of cidr blocks to create public subnet with"
}

variable "private_subnet_cidr_blocks" {
  type = list(string)
  description = "list of cidr blocks to create public subnet with"
}


variable "vpc_cidr_block" {
  type = string
  description = "cidr block to create vpc with"
}

variable "service_name" {
  type = string
  description = "Service name of service"
}

variable "release_version" {
  type = string
  description = "Service name of service"
  default = ""

} 


variable "cluster_name" {
  type        = string
  description = "name of the cluster"
}


variable "repository_url" {
  type = string 
  description  = "Variable for Repository url"
  default = ""

}
 
 variable "sgsid_ecs_efs" {
  type= string
  description  = "Variable for Repository url"
  default = ""
   
 }

 variable "vpc_network" {
  type= string
  description  = "Variable for Repository url"
  default = ""
   
 }
