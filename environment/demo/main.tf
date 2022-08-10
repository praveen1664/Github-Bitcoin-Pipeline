# Module to create a VPC network & Subnets 
module "vpc" {
  source  = "../../modules/vpc"
  env = var.env
  public_subnet_cidr_blocks = var.public_subnet_cidr_blocks
  private_subnet_cidr_blocks = var.private_subnet_cidr_blocks
  vpc_cidr_block = var.vpc_cidr_block
  efs =  "${module.sgs.efs}"
}

# Module to Create Required Security Groups
module "sgs" {
  source  = "../../modules/sgs"
  vpc_id  = "${module.vpc.vpcid}"
}

# Module to Create ECR repository
/* module "ecr" {
  source               = "../../modules/ecr"
  image_tag_mutability = var.image_tag_mutability
  ecr_name = var.ecr_name
  env = var.env
} */

# Module to Create ECS 
module "ecs" {
  source = "../../modules/ecs"
  /* repository_url = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/demo_app" */
  /* "${module.ecr.repository_url}" */
  service_name = var.service_name
  env = var.env
  release_version = var.release_version
  private_subnet = "${module.vpc.private_subnet_ids}"
  sgs_id_ecs =  "${module.sgs.sgsid_ecs}"
  efs_id    =  "${module.vpc.efs_id}"
  public_subnet = "${module.vpc.public_subnet_ids}"
/* depends_on = [module.ecr] */
}


