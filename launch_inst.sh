#! /bin/bash
#
# Скрипт создания любого количества инстансов AWS EC2 по шаблону и балансировщика нагрузки для них
# Cоздаваемые инстансы равномерно распределены по доступным Availability Zones в настройке по умолчанию:
# одна Availability Zone - одна Subnet
#  
# Требуемые входные данные:
# 
# Количество инстансов $1
# ID и версия шаблона (предварительно созданного) $2 $3
# Имя ALB и TG для создаваемой инфраструктуры $4 $5
# ID Security Group для балансировщика (ПОКА предварительно созданной) $6
#
# Скрипт для настройки серверов и деплоя приложений script.txt
#
# Пример: ./launch_inst.sh 4 lt-04b30e2dc9209f94b 1 test-ALB test-target-group sg-0be89dd414f0479d5

# Считываем имеющиеся подсети в массив $subnets
read -a subnets <<< $(aws ec2 describe-subnets --query "Subnets"[].SubnetId --output text)

var=$1                 # количество инстансов
slots=${#subnets[*]}    # количество подсетей

# Определяем количество инстансов для каждой подсети в массив $count_inst
result=$((var / slots))
k=$((var % slots ))
for ((i=0; i < $slots; i++)); do
	if ((k > 0)); then
		count_inst[i]=$((result + 1))
		(( k-- ))
	else
		count_inst[i]=$result
	fi
done

# Создаём Load Balancer
lb_arn=$(aws elbv2 create-load-balancer --name $4 --subnets ${subnets[*]} --security-groups $6 --query "LoadBalancers"[].LoadBalancerArn --output text)

# Получаем ID VPC, в которой создан Load Balancer
vpc_id=$(aws elbv2 describe-load-balancers --load-balancer-arns $lb_arn --query "LoadBalancers"[].VpcId --output text)

# Создаём Target Group
tgrp_arn=$(aws elbv2 create-target-group --name $5 --protocol HTTP --port 80 --vpc-id $vpc_id --query "TargetGroups"[].TargetGroupArn --output text)

# Создаём инстансы в разных Availability Zones  !!! Добавить IP в вывод веб-сервера
a=" "
for ((i=0; i < $slots; i++)); do

	new_inst="$(aws ec2 run-instances --launch-template LaunchTemplateId=$2,Version=$3 --subnet-id ${subnets[$i]} --user-data file://script.txt --count ${count_inst[i]} --query "Instances"[].InstanceId --output text)"
	a="$new_inst $a"
done
read -a instances <<< $a

# Проверяем запуск
for inst_id in ${instances[@]}; do

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

# Регистрируем инстансы в Target Group
for inst_id in ${instances[@]}; do
	aws elbv2 register-targets --target-group-arn $tgrp_arn --targets "Id=${inst_id}"
done

# Создаём Listener для ALB
aws elbv2 create-listener --load-balancer-arn $lb_arn --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$tgrp_arn > /dev/null

while true; do
	alb_st="$(aws elbv2 describe-load-balancers --load-balancer-arns $lb_arn --query "LoadBalancers"[].State.Code --output text)"
		if [ "$alb_st" = "active" ] ; then				
			break # балансер запущен
		fi
		#echo "Status of ALB is: ${alb_st}"
		sleep 1; 
done
echo "ALB is active."




