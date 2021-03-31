#! /bin/bash
#
# Скрипт создания ASG (EC2 Auto Scaling) по шаблону и балансировщика нагрузки 
#  
# Требуемые входные данные:
# -----------------------------------------------------------------------------
# ID и версия шаблона (предварительно созданного) $1 $2
# Имя создаваемой инфраструктуры $3
# ID Security Group для балансировщика (ПОКА предварительно созданной) $4
#
# Минимальное, максимальное и желаемое при старте количество инстансов $5 $6 $7
# ------------------------------------------------------------------------------

# Считываем имеющиеся подсети в массив $subnets
read -a subnets <<< $(aws ec2 describe-subnets --query "Subnets"[].SubnetId --output text)
subnets_str=`echo ${subnets[@]} | tr ' ' ','`

# Создаём Load Balancer
lb_arn=$(aws elbv2 create-load-balancer --name "$3-ALB" --subnets ${subnets[*]} --security-groups $4 --query "LoadBalancers"[].LoadBalancerArn --output text)

# Получаем ID VPC, в которой создан Load Balancer
vpc_id=$(aws elbv2 describe-load-balancers --load-balancer-arns $lb_arn --query "LoadBalancers"[].VpcId --output text)

# Создаём Target Group
tgrp_arn=$(aws elbv2 create-target-group --name "$3-TG" --protocol HTTP --port 80 --vpc-id $vpc_id --query "TargetGroups"[].TargetGroupArn --output text)

# Создаём Listener для ALB
aws elbv2 create-listener --load-balancer-arn $lb_arn --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$tgrp_arn > /dev/null

# Создаём ASG
aws autoscaling create-auto-scaling-group --auto-scaling-group-name "$3-ASG" --launch-template LaunchTemplateId=$1,Version=$2 \
    --vpc-zone-identifier "$subnets_str" --target-group-arns $tgrp_arn \
    --min-size $5 --max-size $6 --desired-capacity $7  
