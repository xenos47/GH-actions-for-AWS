#! /bin/bash

instances=$(sudo docker run --rm -v ~/.aws:/root/.aws amazon/aws-cli ec2 run-instances --launch-template LaunchTemplateId=lt-04b30e2dc9209f94b,Version=1 --count 2 --query "Instances"[].InstanceId --output text)

for inst_id in $instances; do

	while true; 
	do
		inst_st="$(sudo docker run --rm -v ~/.aws:/root/.aws amazon/aws-cli ec2 describe-instance-status --instance-id $inst_id --include-all-instances --query "InstanceStatuses"[].InstanceState.Code --output text)"
			if [ "$inst_st" = "16" ] ; then
				
				break # or add more commands to finilize the process
			fi

			echo "Status of instance with id: ${inst_id} is: ${inst_st}"
			sleep 1; 
        done

	echo "Instance with id: ${inst_id} is running!!!"

done


#inst_st=$(($inst_st + 1)) Получение цифровых значений из строки в bash
