#!/usr/bin/expect -f

spawn aws ecs list-tasks --cluster production-passion --desired-status RUNNING --service-name production-independence --max-items 1 --output text --query taskArns\[0\]
expect "%"
set task_arn [lindex [split $expect_out(buffer) \n] 0]
puts "task_arn: $task_arn"

eval spawn "aws ecs describe-tasks --tasks $task_arn --cluster production-passion --output text --query tasks\\\[0\\\].\\\[containerInstanceArn\\\]"
expect "%"
set container_instance_arn [lindex $expect_out(buffer) 0]
puts "container_instance_arn: $container_instance_arn"

eval spawn "aws ecs describe-container-instances --cluster production-passion --container-instances $container_instance_arn --output text --query containerInstances\\\[0\\\].\\\[ec2InstanceId\\\]"
expect "%"
set ec2_instance_id [lindex $expect_out(buffer) 0]
puts "ec2_instance_id: $ec2_instance_id"

eval spawn "aws ec2 describe-instances --instance-ids $ec2_instance_id --output text --query Reservations\\\[0\\\].Instances\\\[0\\\].\\\[PrivateDnsName\\\]"
expect "%"
set private_dns_name [lindex $expect_out(buffer) 0]
puts "private_dns_name: $private_dns_name"

spawn ssh -i ~/.ssh/passion_ecs -A centos@3.220.135.33
send "ssh ec2-user@$private_dns_name\r"
send "docker exec -it  \$( docker ps --format \"{{.ID}} {{.Command}}\" | grep web | cut -d' ' -f 1) /bin/bash\r"
send "bundle exec rails c production\r"
interact

