variable "env" {
  type        = string
  description = "name of the env i.e. dev/prod/uat/test"
}

variable "release_version" {
  type = string
  description = "Image version which needs to be deployed"
  default = ""
}

/* variable "repository_url" {
  type = string
  default="${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/demo_app"
} */


variable "DATABASE_URL" {
  type = string 
  description  = "Variable for Databse url"
  default = ""
}

variable "sgs_id_ecs" {
  type = string
}

variable "private_subnet" {
  type = list(string)
}

variable "service_name" {
  type = string
}

variable "efs_id" {
  type = string
}

variable "public_subnet" {
  type = list(string)
}
