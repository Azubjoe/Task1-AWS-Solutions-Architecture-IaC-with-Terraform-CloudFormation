# Project Overview

Designed a fault-tolerant, scalable architecture for Django App using AWS services and automated the infrastructure deployment using both Terraform and CloudFormation

## Main AWS Services Used

- EC2 Auto Scaling Group (in 2 or more Availability Zones).
- Application Load Balancer (ALB) for routing traffic to the EC2
instances.
- Amazon RDS (PostgreSQL) as the database backend (using the RDS
configuration already in the app).
- S3 for storing static files and logs.
- CloudWatch for monitoring and alerting.

## Deployment Plan
Refer to the respective deployment instruction documements in this repo.
