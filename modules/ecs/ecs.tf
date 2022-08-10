# Create cloudformation Log group #

resource "aws_cloudwatch_log_group" "demo" {
  name = "demo"
}



## ECS Cluster Creation ##

resource "aws_ecs_cluster" "cluster" {
  name = "${var.service_name}-${var.env}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}


## ECS Task Defnition Creation #

  ## ECS Section #

resource "aws_ecs_task_definition" "app" {
  family = "demo"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  
    container_definitions = <<DEFINITION
[
  {
      "memory": 128,
      "cpu": 10,
      "portMappings": [
          {
              "hostPort": 8332,
              "containerPort": 8332,
              "protocol": "tcp"
          },
      {
              "hostPort": 8333,
              "containerPort": 8333,
              "protocol": "tcp"
          }

      ],
      "essential": true,
      "mountPoints": [
          {
              "containerPath": "/bitcoin",
              "sourceVolume": "efs-data"
          }
      ],
     "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "demo",
                    "awslogs-region": "us-east-1",
                    "awslogs-stream-prefix": "demo-app"
                }
            }, 
      "name": "bitcoin",
       "image" : "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/demo_app:${var.release_version}"
  }
]
DEFINITION
 

  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu          = "256"
  memory       = "2048"


volume {
    name      = "efs-data"
    efs_volume_configuration {
      file_system_id = var.efs_id
    }
  }  
}


resource "aws_ecs_service" "demo-service" {
  name            = "demo-service"
  cluster         = "${var.service_name}-${var.env}"
  task_definition = "${aws_ecs_task_definition.app.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"
  platform_version = "1.4.0" //not specfying this version explictly will not currently work for mounting EFS to Fargate
  network_configuration {
    security_groups  = [var.sgs_id_ecs, var.sgs_id_efs]
    subnets          = var.public_subnet
    assign_public_ip = true
  }  
}
  
