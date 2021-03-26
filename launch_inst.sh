#! /bin/bash

#instances=$(aws ec2 run-instances --launch-template LaunchTemplateId=$1,Version=$2 --count 2 --query "Instances"[].InstanceId --output text)

#for inst_id in $instances; do
#
#	while true; 
#	do
#		inst_st="$(aws ec2 describe-instance-status --instance-id $inst_id --include-all-instances --query "InstanceStatuses"[].InstanceState.Code --output text)"
#			if [ "$inst_st" = "16" ] ; then
#				
#				break # or add more commands to finilize the process
#			fi
#
#			echo "Status of instance with id: ${inst_id} is: ${inst_st}"
#			sleep 1; 
#        done
#
#	echo "Instance with id: ${inst_id} is running!!!"
#
#done

lb_values=$(aws elbv2 create-load-balancer --name $3 --subnets $4 $5 --security-groups $6 --query "LoadBalancers"[].{LoadBalancerArn, VpcId} --output text)

lb_arn="${lb_values[0]}"    # Получаем два значения из --query запроса
vpc_id="${lb_values[1]}"    # строкой выше


#tgrp_arn=$(  )

echo "LoadBalancerArn: ${lb_arn} VpcId: ${vpc_id}"

