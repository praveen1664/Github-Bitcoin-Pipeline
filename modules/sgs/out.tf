output "sgsid" {
  value = aws_security_group.alb_sgs.id
}

output "sgsid_ecs" {
  value = aws_security_group.ecs.id
}

output "sgsid_ecs_host" {
  value = aws_security_group.ecs_host_sg.id
}