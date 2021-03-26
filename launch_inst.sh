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

lb_arn=$(aws elbv2 create-load-balancer --name $3 --subnets $4 $5 --security-groups $6 --query "LoadBalancers"[].LoadBalancerArn --output text)
vpc_id=$(aws elbv2 describe-load-balancers --load-balancer-arns $lb_arn --query "LoadBalancers"[].VpcId --output text)
tgrp_arn=$(aws elbv2 create-target-group --name $7 --protocol HTTP --port 80 --vpc-id $vpc_id --query "TargetGroups"[].TargetGroupArn --output text)




echo "LoadBalancerArn: ${lb_arn} VpcId: ${vpc_id} TargetGroupArn: ${tgrp_arn}"

