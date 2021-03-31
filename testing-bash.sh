#! /bin/bash
#
# Простая проверки bash-скриптов
#  
# 

# Считываем имеющиеся подсети в массив $subnets
read -a subnets <<< $(aws ec2 describe-subnets --query "Subnets"[].SubnetId --output text)

# Создаём Load Balancer
aws elbv2 create-load-balancer --name "$1 load balancer" --subnets ${subnets[*]} --security-groups $2 > /dev/null
