#! /bin/bash
#
# На локальной машине awscli работает в docker-контейнере
# Для работы в GH actions необходимо заменить:
# "sudo docker run --rm -v ~/.aws:/root/.aws amazon/aws-cli" на "aws"
# (На будущее - настроить подстановку, чтобы менять настройку в одном месте)



read -a subnets <<< $(sudo docker run --rm -v ~/.aws:/root/.aws amazon/aws-cli ec2 describe-subnets --query "Subnets"[].SubnetId --output text)

var=$1                  # количество инстансов
slots=${#subnets[*]}    # количество подсетей
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

echo -e "${subnets[*]}"
echo -e "${count_inst[*]}"

# Создаём инстансы в разных Availability !!! Добавить IP в вывод веб-сервера


a=" "
for ((i=0; i < $slots; i++)); do

	new_inst="$(sudo docker run --rm -v ~/.aws:/root/.aws amazon/aws-cli ec2 run-instances --launch-template LaunchTemplateId=$2,Version=$3 --subnet-id ${subnets[$i]} --user-data script1.txt --count ${count_inst[i]} --query "Instances"[].InstanceId --output text)"

	a="$new_inst $a"
	echo "$a"

#instances[i]="${count_inst[i]}"

done

read -a instances <<< $a

echo "${instances[*]}"


