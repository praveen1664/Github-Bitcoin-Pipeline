variable "image_tag_mutability" {
  default = "MUTABLE"
}

variable "ecr_name" {
  type        = string
  description = "Name of the ECR repo"
  default = "bitcoinecr"
}

variable "env" {
  type        = string
  description = "name of the env i.e. dev/prod/uat/test"
}