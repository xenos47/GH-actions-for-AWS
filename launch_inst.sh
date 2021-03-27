#! /bin/bash

# Создаём инстансы в разных Availability Zones --- ДОБАВИТЬ Subnets!!! и запуск веб-сервера

inst_az_1=$(aws ec2 run-instances --launch-template LaunchTemplateId=$1,Version=$2 --count 1 --query "Instances"[].InstanceId --output text)
inst_az_2=$(aws ec2 run-instances --launch-template LaunchTemplateId=$1,Version=$2 --count 1 --query "Instances"[].InstanceId --output text)

# Ожидаем запуска первой группы
for inst_id in $inst_az_1; do

	while true; 
	do
		inst_st="$(aws ec2 describe-instance-status --instance-id $inst_id --include-all-instances --query "InstanceStatuses"[].InstanceState.Code --output text)"
			if [ "$inst_st" = "16" ] ; then
				
				break # сервер запущен
			fi

			echo "Status of instance with id: ${inst_id} is: ${inst_st}"
			sleep 1; 
        done

	echo "Instance with id: ${inst_id} is running!!!"
	
done

# Ожидаем запуска второй группы
for inst_id in $inst_az_2; do

	while true; 
	do
		inst_st="$(aws ec2 describe-instance-status --instance-id $inst_id --include-all-instances --query "InstanceStatuses"[].InstanceState.Code --output text)"
			if [ "$inst_st" = "16" ] ; then
				
				break # сервер запущен
			fi

			echo "Status of instance with id: ${inst_id} is: ${inst_st}"
			sleep 1; 
        done

	echo "Instance with id: ${inst_id} is running!!!"
	
done

# Создаём Load Balancer
lb_arn=$(aws elbv2 create-load-balancer --name $3 --subnets $4 $5 --security-groups $6 --query "LoadBalancers"[].LoadBalancerArn --output text)

# Получаем ID VPC, в которой создан Load Balancer
vpc_id=$(aws elbv2 describe-load-balancers --load-balancer-arns $lb_arn --query "LoadBalancers"[].VpcId --output text)

# Создаём Target Group
tgrp_arn=$(aws elbv2 create-target-group --name $7 --protocol HTTP --port 80 --vpc-id $vpc_id --query "TargetGroups"[].TargetGroupArn --output text)

# Регистрируем инстансы первой зоны в Target Group
for inst_id in $inst_az_1; do
	aws elbv2 register-targets --target-group-arn $tgrp_arn --targets "Id=${inst_id}"
done

# Регистрируем инстансы второй зоны в Target Group
for inst_id in $inst_az_2; do
	aws elbv2 register-targets --target-group-arn $tgrp_arn --targets "Id=${inst_id}"
done

# Создаём Listener для ALB -- нужно продумать output !!!
aws elbv2 create-listener --load-balancer-arn $lb_arn --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$tgrp_arn

