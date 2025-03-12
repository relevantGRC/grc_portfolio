# Lab 8: Infrastructure and Network Protection - Step-by-Step Guide

This guide will walk you through implementing comprehensive infrastructure and network protection in AWS. Follow each module in sequence to build a complete solution.

## Prerequisites

Before starting, ensure you have:

- An AWS account with administrative access
- AWS CLI installed and configured
- Basic understanding of networking concepts
- Familiarity with VPC, subnets, and routing

## Module 1: Secure VPC Design

In this module, you'll create a secure multi-tier VPC architecture.

### Step 1.1: Create VPC and Subnets

1. Create a VPC with appropriate CIDR block:
   ```bash
   aws ec2 create-vpc \
     --cidr-block 10.0.0.0/16 \
     --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=SecureVPC},{Key=Purpose,Value=Lab8}]' \
     --query 'Vpc.VpcId' \
     --output text
   ```

2. Enable DNS hostnames and support:
   ```bash
   VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=SecureVPC" --query 'Vpcs[0].VpcId' --output text)
   
   aws ec2 modify-vpc-attribute \
     --vpc-id $VPC_ID \
     --enable-dns-hostnames
   
   aws ec2 modify-vpc-attribute \
     --vpc-id $VPC_ID \
     --enable-dns-support
   ```

3. Create subnets in two availability zones:
   ```bash
   # Get AZs
   AZ1=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[0].ZoneName' --output text)
   AZ2=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[1].ZoneName' --output text)
   
   # Public Subnets
   aws ec2 create-subnet \
     --vpc-id $VPC_ID \
     --cidr-block 10.0.1.0/24 \
     --availability-zone $AZ1 \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public-1},{Key=Purpose,Value=Lab8}]'
   
   aws ec2 create-subnet \
     --vpc-id $VPC_ID \
     --cidr-block 10.0.2.0/24 \
     --availability-zone $AZ2 \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public-2},{Key=Purpose,Value=Lab8}]'
   
   # Private Web Tier
   aws ec2 create-subnet \
     --vpc-id $VPC_ID \
     --cidr-block 10.0.11.0/24 \
     --availability-zone $AZ1 \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private-Web-1},{Key=Purpose,Value=Lab8}]'
   
   aws ec2 create-subnet \
     --vpc-id $VPC_ID \
     --cidr-block 10.0.12.0/24 \
     --availability-zone $AZ2 \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private-Web-2},{Key=Purpose,Value=Lab8}]'
   
   # Private App Tier
   aws ec2 create-subnet \
     --vpc-id $VPC_ID \
     --cidr-block 10.0.21.0/24 \
     --availability-zone $AZ1 \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private-App-1},{Key=Purpose,Value=Lab8}]'
   
   aws ec2 create-subnet \
     --vpc-id $VPC_ID \
     --cidr-block 10.0.22.0/24 \
     --availability-zone $AZ2 \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private-App-2},{Key=Purpose,Value=Lab8}]'
   
   # Private DB Tier
   aws ec2 create-subnet \
     --vpc-id $VPC_ID \
     --cidr-block 10.0.31.0/24 \
     --availability-zone $AZ1 \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private-DB-1},{Key=Purpose,Value=Lab8}]'
   
   aws ec2 create-subnet \
     --vpc-id $VPC_ID \
     --cidr-block 10.0.32.0/24 \
     --availability-zone $AZ2 \
     --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private-DB-2},{Key=Purpose,Value=Lab8}]'
   ```

### Step 1.2: Set Up Internet Connectivity

1. Create an Internet Gateway:
   ```bash
   IGW_ID=$(aws ec2 create-internet-gateway \
     --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=Lab8-IGW},{Key=Purpose,Value=Lab8}]' \
     --query 'InternetGateway.InternetGatewayId' \
     --output text)
   
   aws ec2 attach-internet-gateway \
     --vpc-id $VPC_ID \
     --internet-gateway-id $IGW_ID
   ```

2. Create NAT Gateways:
   ```bash
   # Allocate Elastic IPs
   EIP1=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)
   EIP2=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)
   
   # Get Public Subnet IDs
   SUBNET_PUBLIC_1=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=Public-1" --query 'Subnets[0].SubnetId' --output text)
   SUBNET_PUBLIC_2=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=Public-2" --query 'Subnets[0].SubnetId' --output text)
   
   # Create NAT Gateways
   NGW1=$(aws ec2 create-nat-gateway \
     --subnet-id $SUBNET_PUBLIC_1 \
     --allocation-id $EIP1 \
     --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=NAT-1},{Key=Purpose,Value=Lab8}]' \
     --query 'NatGateway.NatGatewayId' \
     --output text)
   
   NGW2=$(aws ec2 create-nat-gateway \
     --subnet-id $SUBNET_PUBLIC_2 \
     --allocation-id $EIP2 \
     --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=NAT-2},{Key=Purpose,Value=Lab8}]' \
     --query 'NatGateway.NatGatewayId' \
     --output text)
   ```

### Step 1.3: Configure Route Tables

1. Create and configure route tables:
   ```bash
   # Public Route Table
   PUBLIC_RT=$(aws ec2 create-route-table \
     --vpc-id $VPC_ID \
     --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Public-RT},{Key=Purpose,Value=Lab8}]' \
     --query 'RouteTable.RouteTableId' \
     --output text)
   
   aws ec2 create-route \
     --route-table-id $PUBLIC_RT \
     --destination-cidr-block 0.0.0.0/0 \
     --gateway-id $IGW_ID
   
   # Private Route Tables
   PRIVATE_RT_1=$(aws ec2 create-route-table \
     --vpc-id $VPC_ID \
     --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Private-RT-1},{Key=Purpose,Value=Lab8}]' \
     --query 'RouteTable.RouteTableId' \
     --output text)
   
   PRIVATE_RT_2=$(aws ec2 create-route-table \
     --vpc-id $VPC_ID \
     --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Private-RT-2},{Key=Purpose,Value=Lab8}]' \
     --query 'RouteTable.RouteTableId' \
     --output text)
   
   # Add routes to NAT Gateways
   aws ec2 create-route \
     --route-table-id $PRIVATE_RT_1 \
     --destination-cidr-block 0.0.0.0/0 \
     --nat-gateway-id $NGW1
   
   aws ec2 create-route \
     --route-table-id $PRIVATE_RT_2 \
     --destination-cidr-block 0.0.0.0/0 \
     --nat-gateway-id $NGW2
   ```

2. Associate route tables with subnets:
   ```bash
   # Get Subnet IDs
   SUBNET_WEB_1=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=Private-Web-1" --query 'Subnets[0].SubnetId' --output text)
   SUBNET_WEB_2=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=Private-Web-2" --query 'Subnets[0].SubnetId' --output text)
   SUBNET_APP_1=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=Private-App-1" --query 'Subnets[0].SubnetId' --output text)
   SUBNET_APP_2=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=Private-App-2" --query 'Subnets[0].SubnetId' --output text)
   SUBNET_DB_1=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=Private-DB-1" --query 'Subnets[0].SubnetId' --output text)
   SUBNET_DB_2=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=Private-DB-2" --query 'Subnets[0].SubnetId' --output text)
   
   # Associate Public Subnets
   aws ec2 associate-route-table \
     --subnet-id $SUBNET_PUBLIC_1 \
     --route-table-id $PUBLIC_RT
   
   aws ec2 associate-route-table \
     --subnet-id $SUBNET_PUBLIC_2 \
     --route-table-id $PUBLIC_RT
   
   # Associate Private Subnets AZ1
   aws ec2 associate-route-table \
     --subnet-id $SUBNET_WEB_1 \
     --route-table-id $PRIVATE_RT_1
   
   aws ec2 associate-route-table \
     --subnet-id $SUBNET_APP_1 \
     --route-table-id $PRIVATE_RT_1
   
   aws ec2 associate-route-table \
     --subnet-id $SUBNET_DB_1 \
     --route-table-id $PRIVATE_RT_1
   
   # Associate Private Subnets AZ2
   aws ec2 associate-route-table \
     --subnet-id $SUBNET_WEB_2 \
     --route-table-id $PRIVATE_RT_2
   
   aws ec2 associate-route-table \
     --subnet-id $SUBNET_APP_2 \
     --route-table-id $PRIVATE_RT_2
   
   aws ec2 associate-route-table \
     --subnet-id $SUBNET_DB_2 \
     --route-table-id $PRIVATE_RT_2
   ```

### Step 1.4: Create VPC Endpoints

1. Create VPC endpoints for AWS services:
   ```bash
   # Create security group for endpoints
   ENDPOINT_SG=$(aws ec2 create-security-group \
     --group-name VPCEndpoint-SG \
     --description "Security group for VPC endpoints" \
     --vpc-id $VPC_ID \
     --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=VPCEndpoint-SG},{Key=Purpose,Value=Lab8}]' \
     --query 'GroupId' \
     --output text)
   
   aws ec2 authorize-security-group-ingress \
     --group-id $ENDPOINT_SG \
     --protocol tcp \
     --port 443 \
     --cidr 10.0.0.0/16
   
   # Create endpoints
   aws ec2 create-vpc-endpoint \
     --vpc-id $VPC_ID \
     --vpc-endpoint-type Interface \
     --service-name com.amazonaws.$(aws configure get region).ssm \
     --subnet-ids $SUBNET_APP_1 $SUBNET_APP_2 \
     --security-group-ids $ENDPOINT_SG \
     --private-dns-enabled \
     --tag-specifications 'ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=SSM-Endpoint},{Key=Purpose,Value=Lab8}]'
   
   aws ec2 create-vpc-endpoint \
     --vpc-id $VPC_ID \
     --vpc-endpoint-type Interface \
     --service-name com.amazonaws.$(aws configure get region).ecr.api \
     --subnet-ids $SUBNET_APP_1 $SUBNET_APP_2 \
     --security-group-ids $ENDPOINT_SG \
     --private-dns-enabled \
     --tag-specifications 'ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=ECR-API-Endpoint},{Key=Purpose,Value=Lab8}]'
   
   aws ec2 create-vpc-endpoint \
     --vpc-id $VPC_ID \
     --vpc-endpoint-type Interface \
     --service-name com.amazonaws.$(aws configure get region).ecr.dkr \
     --subnet-ids $SUBNET_APP_1 $SUBNET_APP_2 \
     --security-group-ids $ENDPOINT_SG \
     --private-dns-enabled \
     --tag-specifications 'ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=ECR-DKR-Endpoint},{Key=Purpose,Value=Lab8}]'
   
   aws ec2 create-vpc-endpoint \
     --vpc-id $VPC_ID \
     --vpc-endpoint-type Gateway \
     --service-name com.amazonaws.$(aws configure get region).s3 \
     --route-table-ids $PRIVATE_RT_1 $PRIVATE_RT_2 \
     --tag-specifications 'ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=S3-Endpoint},{Key=Purpose,Value=Lab8}]'
   ```

## Module 2: Network Access Controls

In this module, you'll configure Network ACLs and security groups.

### Step 2.1: Configure Network ACLs

1. Create Network ACLs for each tier:
   ```bash
   # Create NACLs
   PUBLIC_NACL=$(aws ec2 create-network-acl \
     --vpc-id $VPC_ID \
     --tag-specifications 'ResourceType=network-acl,Tags=[{Key=Name,Value=Public-NACL},{Key=Purpose,Value=Lab8}]' \
     --query 'NetworkAcl.NetworkAclId' \
     --output text)
   
   WEB_NACL=$(aws ec2 create-network-acl \
     --vpc-id $VPC_ID \
     --tag-specifications 'ResourceType=network-acl,Tags=[{Key=Name,Value=Web-NACL},{Key=Purpose,Value=Lab8}]' \
     --query 'NetworkAcl.NetworkAclId' \
     --output text)
   
   APP_NACL=$(aws ec2 create-network-acl \
     --vpc-id $VPC_ID \
     --tag-specifications 'ResourceType=network-acl,Tags=[{Key=Name,Value=App-NACL},{Key=Purpose,Value=Lab8}]' \
     --query 'NetworkAcl.NetworkAclId' \
     --output text)
   
   DB_NACL=$(aws ec2 create-network-acl \
     --vpc-id $VPC_ID \
     --tag-specifications 'ResourceType=network-acl,Tags=[{Key=Name,Value=DB-NACL},{Key=Purpose,Value=Lab8}]' \
     --query 'NetworkAcl.NetworkAclId' \
     --output text)
   ```

2. Configure NACL rules for public subnets:
   ```bash
   # Inbound rules
   aws ec2 create-network-acl-entry \
     --network-acl-id $PUBLIC_NACL \
     --rule-number 100 \
     --protocol tcp \
     --port-range From=80,To=80 \
     --cidr-block 0.0.0.0/0 \
     --rule-action allow \
     --ingress
   
   aws ec2 create-network-acl-entry \
     --network-acl-id $PUBLIC_NACL \
     --rule-number 110 \
     --protocol tcp \
     --port-range From=443,To=443 \
     --cidr-block 0.0.0.0/0 \
     --rule-action allow \
     --ingress
   
   # Outbound rules
   aws ec2 create-network-acl-entry \
     --network-acl-id $PUBLIC_NACL \
     --rule-number 100 \
     --protocol -1 \
     --cidr-block 0.0.0.0/0 \
     --rule-action allow \
     --egress
   ```

3. Configure NACL rules for web tier:
   ```bash
   # Inbound rules
   aws ec2 create-network-acl-entry \
     --network-acl-id $WEB_NACL \
     --rule-number 100 \
     --protocol tcp \
     --port-range From=80,To=80 \
     --cidr-block 10.0.1.0/24 \
     --rule-action allow \
     --ingress
   
   aws ec2 create-network-acl-entry \
     --network-acl-id $WEB_NACL \
     --rule-number 110 \
     --protocol tcp \
     --port-range From=443,To=443 \
     --cidr-block 10.0.1.0/24 \
     --rule-action allow \
     --ingress
   
   # Outbound rules
   aws ec2 create-network-acl-entry \
     --network-acl-id $WEB_NACL \
     --rule-number 100 \
     --protocol tcp \
     --port-range From=80,To=80 \
     --cidr-block 0.0.0.0/0 \
     --rule-action allow \
     --egress
   
   aws ec2 create-network-acl-entry \
     --network-acl-id $WEB_NACL \
     --rule-number 110 \
     --protocol tcp \
     --port-range From=443,To=443 \
     --cidr-block 0.0.0.0/0 \
     --rule-action allow \
     --egress
   ```

### Step 2.2: Configure Security Groups

1. Create security groups for each tier:
   ```bash
   # ALB Security Group
   ALB_SG=$(aws ec2 create-security-group \
     --group-name ALB-SG \
     --description "Security group for Application Load Balancer" \
     --vpc-id $VPC_ID \
     --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=ALB-SG},{Key=Purpose,Value=Lab8}]' \
     --query 'GroupId' \
     --output text)
   
   aws ec2 authorize-security-group-ingress \
     --group-id $ALB_SG \
     --protocol tcp \
     --port 80 \
     --cidr 0.0.0.0/0
   
   aws ec2 authorize-security-group-ingress \
     --group-id $ALB_SG \
     --protocol tcp \
     --port 443 \
     --cidr 0.0.0.0/0
   
   # Web Tier Security Group
   WEB_SG=$(aws ec2 create-security-group \
     --group-name Web-SG \
     --description "Security group for web tier" \
     --vpc-id $VPC_ID \
     --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=Web-SG},{Key=Purpose,Value=Lab8}]' \
     --query 'GroupId' \
     --output text)
   
   aws ec2 authorize-security-group-ingress \
     --group-id $WEB_SG \
     --protocol tcp \
     --port 80 \
     --source-group $ALB_SG
   
   # App Tier Security Group
   APP_SG=$(aws ec2 create-security-group \
     --group-name App-SG \
     --description "Security group for app tier" \
     --vpc-id $VPC_ID \
     --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=App-SG},{Key=Purpose,Value=Lab8}]' \
     --query 'GroupId' \
     --output text)
   
   aws ec2 authorize-security-group-ingress \
     --group-id $APP_SG \
     --protocol tcp \
     --port 8080 \
     --source-group $WEB_SG
   
   # DB Security Group
   DB_SG=$(aws ec2 create-security-group \
     --group-name DB-SG \
     --description "Security group for database tier" \
     --vpc-id $VPC_ID \
     --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=DB-SG},{Key=Purpose,Value=Lab8}]' \
     --query 'GroupId' \
     --output text)
   
   aws ec2 authorize-security-group-ingress \
     --group-id $DB_SG \
     --protocol tcp \
     --port 3306 \
     --source-group $APP_SG
   ```

## Module 3: DDoS Protection

In this module, you'll implement DDoS protection using AWS Shield and AWS WAF.

### Step 3.1: Enable AWS Shield Advanced

1. Enable AWS Shield Advanced:
   ```bash
   aws shield subscribe
   ```

2. Create a CloudWatch alarm for DDoS events:
   ```bash
   aws cloudwatch put-metric-alarm \
     --alarm-name DDoS-Detection \
     --alarm-description "Alarm for DDoS events" \
     --metric-name DDoSDetected \
     --namespace AWS/DDoSProtection \
     --statistic Sum \
     --period 300 \
     --threshold 1 \
     --comparison-operator GreaterThanThreshold \
     --evaluation-periods 1 \
     --alarm-actions $SNS_TOPIC_ARN
   ```

### Step 3.2: Configure AWS WAF

1. Create an AWS WAF web ACL:
   ```bash
   # Create IP rate limiting rule
   aws wafv2 create-ip-set \
     --name RateLimitIPs \
     --scope REGIONAL \
     --ip-address-version IPV4 \
     --addresses

   RULE_GROUP_ID=$(aws wafv2 create-rule-group \
     --name RateLimitRules \
     --scope REGIONAL \
     --capacity 100 \
     --rules '[
       {
         "Name": "RateLimit",
         "Priority": 1,
         "Statement": {
           "RateBasedStatement": {
             "Limit": 2000,
             "AggregateKeyType": "IP"
           }
         },
         "Action": {
           "Block": {}
         },
         "VisibilityConfig": {
           "SampledRequestsEnabled": true,
           "CloudWatchMetricsEnabled": true,
           "MetricName": "RateLimitRule"
         }
       }
     ]' \
     --visibility-config SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=RateLimitRuleGroup \
     --query 'Summary.Id' \
     --output text)

   # Create Web ACL
   aws wafv2 create-web-acl \
     --name SecurityLab-WAF \
     --scope REGIONAL \
     --default-action Allow={} \
     --rules '[
       {
         "Name": "AWSManagedRulesCommonRuleSet",
         "Priority": 1,
         "OverrideAction": { "None": {} },
         "Statement": {
           "ManagedRuleGroupStatement": {
             "VendorName": "AWS",
             "Name": "AWSManagedRulesCommonRuleSet"
           }
         },
         "VisibilityConfig": {
           "SampledRequestsEnabled": true,
           "CloudWatchMetricsEnabled": true,
           "MetricName": "AWSManagedRulesCommonRuleSetMetric"
         }
       },
       {
         "Name": "AWSManagedRulesKnownBadInputsRuleSet",
         "Priority": 2,
         "OverrideAction": { "None": {} },
         "Statement": {
           "ManagedRuleGroupStatement": {
             "VendorName": "AWS",
             "Name": "AWSManagedRulesKnownBadInputsRuleSet"
           }
         },
         "VisibilityConfig": {
           "SampledRequestsEnabled": true,
           "CloudWatchMetricsEnabled": true,
           "MetricName": "AWSManagedRulesKnownBadInputsRuleSetMetric"
         }
       },
       {
         "Name": "RateLimitRule",
         "Priority": 3,
         "Statement": {
           "RuleGroupReferenceStatement": {
             "ARN": "'$RULE_GROUP_ID'"
           }
         },
         "VisibilityConfig": {
           "SampledRequestsEnabled": true,
           "CloudWatchMetricsEnabled": true,
           "MetricName": "RateLimitRuleMetric"
         }
       }
     ]' \
     --visibility-config SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=SecurityLabWAF
   ```

## Module 4: Network Monitoring

In this module, you'll implement network monitoring using VPC Flow Logs and GuardDuty.

### Step 4.1: Enable VPC Flow Logs

1. Create a CloudWatch log group for flow logs:
   ```bash
   aws logs create-log-group \
     --log-group-name /aws/vpc/flowlogs
   ```

2. Create an IAM role for flow logs:
   ```bash
   # Create trust policy
   cat > flowlogs-trust-policy.json << EOF
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Service": "vpc-flow-logs.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
       }
     ]
   }
   EOF
   
   # Create role
   FLOW_LOGS_ROLE=$(aws iam create-role \
     --role-name VPCFlowLogsRole \
     --assume-role-policy-document file://flowlogs-trust-policy.json \
     --query 'Role.Arn' \
     --output text)
   
   # Create policy
   cat > flowlogs-policy.json << EOF
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "logs:CreateLogGroup",
           "logs:CreateLogStream",
           "logs:PutLogEvents",
           "logs:DescribeLogGroups",
           "logs:DescribeLogStreams"
         ],
         "Resource": "*"
       }
     ]
   }
   EOF
   
   aws iam put-role-policy \
     --role-name VPCFlowLogsRole \
     --policy-name VPCFlowLogsPolicy \
     --policy-document file://flowlogs-policy.json
   ```

3. Enable flow logs for the VPC:
   ```bash
   aws ec2 create-flow-logs \
     --resource-type VPC \
     --resource-ids $VPC_ID \
     --traffic-type ALL \
     --log-group-name /aws/vpc/flowlogs \
     --deliver-logs-permission-arn $FLOW_LOGS_ROLE
   ```

### Step 4.2: Enable GuardDuty

1. Enable GuardDuty:
   ```bash
   aws guardduty create-detector \
     --enable \
     --finding-publishing-frequency FIFTEEN_MINUTES
   ```

2. Create a CloudWatch event rule for GuardDuty findings:
   ```bash
   aws events put-rule \
     --name GuardDutyFindings \
     --event-pattern '{
       "source": ["aws.guardduty"],
       "detail-type": ["GuardDuty Finding"]
     }'
   
   aws events put-targets \
     --rule GuardDutyFindings \
     --targets "Id"="1","Arn"="$SNS_TOPIC_ARN"
   ```

## Module 5: Network Security Testing

In this module, you'll validate your network security controls.

### Step 5.1: Test Network Connectivity

1. Create a test EC2 instance in the public subnet:
   ```bash
   # Create key pair
   aws ec2 create-key-pair \
     --key-name SecurityLab \
     --query 'KeyMaterial' \
     --output text > SecurityLab.pem
   
   chmod 400 SecurityLab.pem
   
   # Create bastion host
   BASTION_SG=$(aws ec2 create-security-group \
     --group-name Bastion-SG \
     --description "Security group for bastion host" \
     --vpc-id $VPC_ID \
     --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=Bastion-SG},{Key=Purpose,Value=Lab8}]' \
     --query 'GroupId' \
     --output text)
   
   aws ec2 authorize-security-group-ingress \
     --group-id $BASTION_SG \
     --protocol tcp \
     --port 22 \
     --cidr $(curl -s https://checkip.amazonaws.com)/32
   
   BASTION_ID=$(aws ec2 run-instances \
     --image-id ami-0c55b159cbfafe1f0 \
     --instance-type t2.micro \
     --key-name SecurityLab \
     --subnet-id $SUBNET_PUBLIC_1 \
     --security-group-ids $BASTION_SG \
     --associate-public-ip-address \
     --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Bastion},{Key=Purpose,Value=Lab8}]' \
     --query 'Instances[0].InstanceId' \
     --output text)
   ```

2. Test connectivity:
   ```bash
   # Get bastion public IP
   BASTION_IP=$(aws ec2 describe-instances \
     --instance-ids $BASTION_ID \
     --query 'Reservations[0].Instances[0].PublicIpAddress' \
     --output text)
   
   # Test SSH access
   ssh -i SecurityLab.pem ec2-user@$BASTION_IP
   ```

### Step 5.2: Test Security Controls

1. Test WAF rules:
   ```bash
   # Test rate limiting
   for i in {1..100}; do
     curl -s -o /dev/null -w "%{http_code}\n" http://$ALB_DNS
   done
   ```

2. Monitor CloudWatch for security events:
   ```bash
   aws logs tail /aws/vpc/flowlogs --follow
   ```

## Cleanup

To avoid ongoing charges, delete all resources created in this lab:

1. Delete EC2 instances:
   ```bash
   aws ec2 terminate-instances --instance-ids $BASTION_ID
   ```

2. Delete security groups:
   ```bash
   for sg in $BASTION_SG $ALB_SG $WEB_SG $APP_SG $DB_SG $ENDPOINT_SG; do
     aws ec2 delete-security-group --group-id $sg
   done
   ```

3. Delete NAT Gateways and release Elastic IPs:
   ```bash
   aws ec2 delete-nat-gateway --nat-gateway-id $NGW1
   aws ec2 delete-nat-gateway --nat-gateway-id $NGW2
   
   aws ec2 release-address --allocation-id $EIP1
   aws ec2 release-address --allocation-id $EIP2
   ```

4. Delete VPC endpoints:
   ```bash
   aws ec2 describe-vpc-endpoints \
     --filters "Name=vpc-id,Values=$VPC_ID" \
     --query 'VpcEndpoints[*].VpcEndpointId' \
     --output text | \
   xargs -n1 aws ec2 delete-vpc-endpoint --vpc-endpoint-id
   ```

5. Delete subnets:
   ```bash
   for subnet in $SUBNET_PUBLIC_1 $SUBNET_PUBLIC_2 $SUBNET_WEB_1 $SUBNET_WEB_2 $SUBNET_APP_1 $SUBNET_APP_2 $SUBNET_DB_1 $SUBNET_DB_2; do
     aws ec2 delete-subnet --subnet-id $subnet
   done
   ```

6. Delete route tables:
   ```bash
   aws ec2 delete-route-table --route-table-id $PUBLIC_RT
   aws ec2 delete-route-table --route-table-id $PRIVATE_RT_1
   aws ec2 delete-route-table --route-table-id $PRIVATE_RT_2
   ```

7. Delete Internet Gateway:
   ```bash
   aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
   aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
   ```

8. Delete VPC:
   ```bash
   aws ec2 delete-vpc --vpc-id $VPC_ID
   ```

9. Delete WAF Web ACL and rule groups:
   ```bash
   aws wafv2 delete-web-acl --name SecurityLab-WAF --scope REGIONAL --id $WEB_ACL_ID
   aws wafv2 delete-rule-group --name RateLimitRules --scope REGIONAL --id $RULE_GROUP_ID
   ```

10. Disable GuardDuty:
    ```bash
    DETECTOR_ID=$(aws guardduty list-detectors --query 'DetectorIds[0]' --output text)
    aws guardduty delete-detector --detector-id $DETECTOR_ID
    ```

11. Delete CloudWatch log group:
    ```bash
    aws logs delete-log-group --log-group-name /aws/vpc/flowlogs
    ```

12. Delete IAM roles and policies:
    ```bash
    aws iam delete-role-policy --role-name VPCFlowLogsRole --policy-name VPCFlowLogsPolicy
    aws iam delete-role --role-name VPCFlowLogsRole
    ```

## Conclusion

Congratulations! You have successfully implemented a comprehensive network security solution in AWS that includes:

- Secure VPC architecture with multiple tiers
- Network ACLs and security groups for defense in depth
- DDoS protection with AWS Shield and WAF
- Network monitoring with VPC Flow Logs and GuardDuty
- Network security testing and validation

These components work together to provide a robust network security posture for your AWS environment. 