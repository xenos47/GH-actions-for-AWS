#-----------------------------------------------------------------------
# Creating Autoscaling Group using Launch Template in AWS EC2
#-----------------------------------------------------------------------

import boto3

ec2_client = boto3.client('ec2')
elb_client = boto3.client('elbv2') 
asg_client = boto3.client('autoscaling')

# Getting lists of Subnet's IDs and Availability Zones
listSubnets = list()
listAvailabilityZones = list()

response = ec2_client.describe_subnets()
for sn in response['Subnets'] :               
        listSubnets.append(sn['SubnetId'])

for az in response['Subnets'] :
        listAvailabilityZones.append(az['AvailabilityZone'])

# Getting Vpc ID
response = ec2_client.describe_vpcs()
strVpcId = response["Vpcs"][0]["VpcId"]

# Creating Load Balancer
response = elb_client.create_load_balancer(
            Name='my-load-balancer',         # Load Balancer's Name  
            Subnets=listSubnets,
            SecurityGroups=[
                'sg-0be89dd414f0479d5'       # ID Security Group
            ],
            )

strLoadBalancerArn = response["LoadBalancers"][0]["LoadBalancerArn"]

# Creating Target Group
listTargetGroupArn = list()

response = elb_client.create_target_group(
            Name='my-targets',               # Target Group's Name
            Port=80,
            Protocol='HTTP',
            VpcId=strVpcId,
            )

strTargetGroupArn = response["TargetGroups"][0]["TargetGroupArn"]
listTargetGroupArn.append(response["TargetGroups"][0]["TargetGroupArn"])

# Creating Listener
response = elb_client.create_listener(
            DefaultActions=[
                        {
                            'TargetGroupArn': strTargetGroupArn,
                            'Type': 'forward',
                        },
            ],
            LoadBalancerArn=strLoadBalancerArn,
            Port=80,
            Protocol='HTTP',
            )

# Creating Autoscaling Group
launch_template_id = "lt-04b30e2dc9209f94b"
autoscaling_group_name = 'awspy_autoscaling_group'
cpu_utilization_trigger_value = 80

response = asg_client.create_auto_scaling_group(
            AutoScalingGroupName = autoscaling_group_name,
            LaunchTemplate={
                'LaunchTemplateId': launch_template_id,
            },
            MinSize=1,
            MaxSize=1,
            DesiredCapacity=1,
            TargetGroupARNs=listTargetGroupArn,
            AvailabilityZones=listAvailabilityZones,
            )

response = asg_client.put_scaling_policy( 
            AutoScalingGroupName = autoscaling_group_name,
            PolicyName = 'AverageCPUUtilization',
            PolicyType = 'TargetTrackingScaling',
            AdjustmentType = 'PercentChangeInCapacity',
            EstimatedInstanceWarmup = 60,
            TargetTrackingConfiguration = { 
                'CustomizedMetricSpecification': { 
                    'MetricName': 'CPUUtilization',
                    'Namespace': 'AWS/EC2',
                    'Dimensions': [{
                        'Name': 'AutoScalingGroupName',
                        'Value': autoscaling_group_name }],
                    'Statistic': 'Average', 
                    'Unit': 'Percent'},
                'TargetValue': cpu_utilization_trigger_value })


