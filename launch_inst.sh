#! /bin/bash

instances=$(aws ec2 run-instances --launch-template LaunchTemplateId=$1,Version=$2 --count 2 --query "Instances"[].InstanceId --output text)

for inst_id in $instances; do

	while true; 
	do
		inst_st="$(aws ec2 describe-instance-status --instance-id $inst_id --include-all-instances --query "InstanceStatuses"[].InstanceState.Code --output text)"
			if [ "$inst_st" = "16" ] ; then
				
				break # or add more commands to finilize the process
			fi

			echo "Status of instance with id: ${inst_id} is: ${inst_st}"
			sleep 1; 
        done

	echo "Instance with id: ${inst_id} is running!!!"

done


#inst_st=$(($inst_st + 1)) Получение цифровых значений из строки в bash
