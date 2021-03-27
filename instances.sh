#! /bin/bash

declare -a id_instances
instances=$(aws ec2 describe-instances --query "Reservations"[]."Instances"[].InstanceId --output text)

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
	echo "Id=${inst_id}"
	#id_instances+=("Id=${inst_id}")
	id_instances+=( apple )
	        
done
#
#for inst_id1 in $id_instances; do
#	echo "The new format: ${inst_id1}"
#done


#inst_st=$(($inst_st + 1)) Получение цифровых значений из строки в bash
