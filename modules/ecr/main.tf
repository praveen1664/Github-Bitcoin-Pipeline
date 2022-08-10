resource "aws_ecr_repository" "image_registry" {
  name                 = "${var.ecr_name}"
  /* name= "BitCoinEcr" */
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = true
  }
}


