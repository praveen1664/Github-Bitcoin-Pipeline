resource "aws_security_group" "alb_sgs" {
  name        = "app_lb_sg"
  description = "Allow http inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description      = "HTTP from internet"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "app_lb_sg"
  }
}

resource "aws_security_group" "sgs_id_ecs" {
  name        = "ecs-container"
  description = "Allow http inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
   # security_groups = [aws_security_group.alb_sgs.id]
    cidr_blocks      = ["0.0.0.0/0"]
  }

  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ecs_sg"
  }
}

resource "aws_security_group" "ecs_host_sg" {
	    vpc_id      = var.vpc_id
	
	    ingress {
	        from_port       = 22
	        to_port         = 22
	        protocol        = "tcp"
	        cidr_blocks     = ["0.0.0.0/0"]
	    }
	
	    ingress {
	        from_port       = 443
	        to_port         = 443
	        protocol        = "tcp"
	        cidr_blocks     = ["0.0.0.0/0"]
	    }
	
	    egress {
	        from_port       = 0
	        to_port         = 65535
	        protocol        = "tcp"
	        cidr_blocks     = ["0.0.0.0/0"]
	    }
}