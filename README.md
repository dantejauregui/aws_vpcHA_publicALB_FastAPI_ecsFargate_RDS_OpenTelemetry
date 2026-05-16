# Public ALB + FastAPI (Python) + ecsFargate + RDS + openTelemetry + Otel Collector

FastAPI application running on AWS ECS Fargate using RDS as persistence layer and OpenTelemetry + Grafana Cloud for observability. (Is not needed "API Gateway" when only ECS is present)



## HA Architecture:
Same ECS service seeing by different traffic directions:

```text
                                       INTERNET
                                           |
                                           |
                                 +-----------------+
                                 | Internet Gateway|
                                 +-----------------+
                                           |
                    =================================================
                    |                                              |
                    |                                              |
        +-----------------------+                  +-----------------------+
        |   Public Subnet AZ-a  |                  |   Public Subnet AZ-b  |
        |      10.0.1.0/24      |                  |      10.0.2.0/24      |
        +-----------------------+                  +-----------------------+
                    |                                              |
                    |                                              |
          +-------------------+                         +-------------------+
          |   NAT Gateway A   |                         |   NAT Gateway B   |
          |      + EIP        |                         |      + EIP        |
          +-------------------+                         +-------------------+
                    |                                              |
                    |                                              |
                    +-------------------+  +-----------------------+
                                        |  |
                                        |  |
                              +----------------------------------+
                              |   Application Load Balancer      |
                              |          (Public ALB)            |
                              |                                  |
                              |  Listener :80                    |
                              |  Target Group :80                |
                              +----------------------------------+
                                              |
                                              |
                              =================================
                                              |
                                              |
                    =================================================
                    |                                              |
                    |                                              |
        +-----------------------+                  +-----------------------+
        |  Private Subnet AZ-a  |                  |  Private Subnet AZ-b  |
        |     10.0.11.0/24      |                  |     10.0.12.0/24      |
        +-----------------------+                  +-----------------------+
                    |                                              |
                    |                                              |
          +-------------------+                         +-------------------+
          | ECS Fargate Task  |                         | ECS Fargate Task  |
          | fastAPIapp container|                      | fastAPIapp container|
          | private IP only   |                         | private IP only   |
          +-------------------+                         +-------------------+
                    |                                              |
                    +-------------------+  +-----------------------+
                                        |  |
                                        |  |
                              +----------------------------------+
                              | ECS Service (desired_count = 2) |
                              +----------------------------------+
                                              |
                                              |
                              +----------------------------------+
                              | ECS Cluster                      |
                              +----------------------------------+



NETWORKING FLOW
================

Ingress:
---------
Internet
   |
IGW
   |
Public ALB
   |
Private ECS Tasks


Egress:
--------
Private ECS Task
   |
Private Route Table
   |
NAT Gateway
   |
IGW
   |
Internet
```



## Creating CICD & Docker image

For creation of image we use in my Mac M1:
docker buildx build -t myapp:latest .


For creating the container we use:
docker run myapp:latest

And we use inside the Dockerfile this line in order to test the Image created:
CMD ["sleep", "infinity"]

## Networking FastApi + Terraform infrastructure:
These FOUR things MUST match:

```
uvicorn --port
=
target group backend port
=
ecs Task Definition containerPort
=
ecs service container_port
=
ecs task SG inbound port
```