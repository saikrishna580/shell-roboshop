#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-01ea0ba910221b5e4" # replace with your SB ID
INSTANCES=("mongodb" "redis" "mysql" "rabbimq" "catalogue" "user" "cart" "shipping" "payment" " "dispatch" "frontend) 
ZONE_ID="Z06674571D4FFWQIC66VP"
DOMAIN_NAME="daw84s.store"

for instance in ${INSTANCES[@]}
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-0220d79f3f480ecf5 --instance-type t3.micro --security-group-ids sg-01ea0ba910221b5e4 --tag-specifications "ResourceType=instance,Tags=[{Key=name,Value=$instance}]" --query "Instances[0].InstanceId" --output text)
    if [ $instance != "frontend" ]
    then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
    else 
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
    fi
    echo "$instance IP address: $IP"    

    aws route53 change-resource-record-sets \
     --hosted-zone-id $ZONE_ID \
     --change-batch '
    {
         "Comment": "Creating or Updating record set for cognito endpoint"
        ,"Changes": [{
         "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
             "Name"              : "'$instance'.'$DOMAIN_NAME'"
           ,"Type"             : "A"
           ,"TTL"              : 1
           ,"ResourceRecords"  : [{
               "Value"         : "$IP"
          }]
        }
      }]
    }"

done
