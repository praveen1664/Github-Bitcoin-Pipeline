output "sgsid" {
  value = aws_security_group.alb_sgs.id
}

output "sgsid_ecs" {
  value = aws_security_group.ecs.id
}

output "efs" {
  value = aws_security_group.efs.id
}

