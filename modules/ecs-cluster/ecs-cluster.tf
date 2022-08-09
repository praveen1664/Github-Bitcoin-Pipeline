## ECS Cluster Creation ##

resource "aws_ecs_cluster" "cluster" {
  name = "${var.service_name}-${var.env}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

## Create Log group for app logs in cloudwatch ##

resource "aws_cloudwatch_log_group" "app" {
  name = "${var.service_name}"

  tags = {
    Environment = "${var.env}"
  }
}