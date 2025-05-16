#!/bin/bash

# Register the task definition
TASK_DEF_ARN=$(aws ecs register-task-definition --cli-input-json file://task-definition.json --query 'taskDefinition.taskDefinitionArn' --output text)

echo "Task definition registered: $TASK_DEF_ARN"

# Get subnet IDs from your VPC
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-0025baef295f27cd8" --query 'Subnets[?MapPublicIpOnLaunch==`false`].SubnetId' --output json)

# Get security group ID for ECS tasks
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=product-service-dev-ecs-sg" --query 'SecurityGroups[0].GroupId' --output text)

# Get target group ARN
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --names product-service-dev-target-group --query 'TargetGroups[0].TargetGroupArn' --output text)

echo "Creating ECS service with:"
echo "Subnets: $SUBNET_IDS"
echo "Security Group: $SECURITY_GROUP_ID"
echo "Target Group: $TARGET_GROUP_ARN"

# Create the service
aws ecs create-service \
  --cluster product-service-dev-cluster \
  --service-name product-service \
  --task-definition $TASK_DEF_ARN \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=$SUBNET_IDS,securityGroups=[$SECURITY_GROUP_ID],assignPublicIp=DISABLED}" \
  --load-balancers "targetGroupArn=$TARGET_GROUP_ARN,containerName=product-service,containerPort=8080"

echo "Service creation initiated. Check AWS Console or run: aws ecs describe-services --cluster product-service-dev-cluster --services product-service"
