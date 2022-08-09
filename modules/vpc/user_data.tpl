#!bin/bash
#Adding cluster name in ecs config
echo ECS_CLUSTER= app-demo >> /etc/ecs/ecs.config
systemctl enable --now --no-block ecs.service
service ecs stop;
rm /var/lib/ecs/data/agent.db;
service ecs start
