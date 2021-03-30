#! /bin/bash
#
# Скрипт создания ASG (EC2 Auto Scaling) по шаблону и балансировщика нагрузки 
#  
# Требуемые входные данные:
# -----------------------------------------------------------------------------
# ID и версия шаблона (предварительно созданного) $1 $2
# Имя ALB и TG для создаваемой инфраструктуры $3 $4
# ID Security Group для балансировщика (ПОКА предварительно созданной) $5
#
# Минимальное, максимальное и желаемое при старте количество инстансов $6 $7 $8
# ------------------------------------------------------------------------------

# Считываем имеющиеся подсети в массив $subnets
read -a subnets <<< $(aws ec2 describe-subnets --query "Subnets"[].SubnetId --output text)
subnets_str=`echo ${subnets[@]} | tr ' ' ','`

# Создаём Load Balancer
lb_arn=$(aws elbv2 create-load-balancer --name $3 --subnets ${subnets[*]} --security-groups $5 --query "LoadBalancers"[].LoadBalancerArn --output text)

# Получаем ID VPC, в которой создан Load Balancer
vpc_id=$(aws elbv2 describe-load-balancers --load-balancer-arns $lb_arn --query "LoadBalancers"[].VpcId --output text)

# Создаём Target Group
tgrp_arn=$(aws elbv2 create-target-group --name $4 --protocol HTTP --port 80 --vpc-id $vpc_id --query "TargetGroups"[].TargetGroupArn --output text)

# Создаём Listener для ALB
aws elbv2 create-listener --load-balancer-arn $lb_arn --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$tgrp_arn > /dev/null

# Создаём ASG
aws autoscaling create-auto-scaling-group --auto-scaling-group-name my-asg --launch-template LaunchTemplateId=$1,Version=$2 \
    --vpc-zone-identifier "$subnets_str" --target-group-arns $tgrp_arn \
    --min-size $6 --max-size $7 --desired-capacity $8  
