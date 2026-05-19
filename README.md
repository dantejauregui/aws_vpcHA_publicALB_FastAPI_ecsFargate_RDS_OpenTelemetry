# Public ALB + FastAPI (Python) + ecsFargate + RDS + openTelemetry + Otel Collector

Production-oriented learning project that deploys a FastAPI application into AWS ECS Fargate behind a public Application Load Balancer using Terraform.

The goal of this repository is not only to deploy a containerized application, but also to understand the operational concepts used in real cloud environments:

* VPC networking
* Public vs Private subnets
* NAT Gateway usage
* ECS task networking
* Container runtime lifecycle
* Health checks
* CI/CD pipelines
* Immutable container artifacts
* Registry publishing
* Infrastructure as Code

---

# Architecture Overview

## High Availability Design

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
                              |  Target Group :8000              |
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
          | FastAPI container |                         | FastAPI container |
          | private IP only   |                         | private IP only   |
          +-------------------+                         +-------------------+
                    |                                              |
                    +-------------------+  +-----------------------+
                                        |  |
                                        |  |
                              +----------------------------------+
                              |         Amazon RDS               |
                              |          PostgreSQL              |
                              +----------------------------------+
```

---

# Networking Design Decisions

## Why the ALB Lives in Public Subnets

The Application Load Balancer receives traffic directly from the internet.

Because of that, it must:

* have public IP reachability
* be attached to public subnets
* route traffic through the Internet Gateway

The ALB acts as the controlled public entrypoint into the VPC.

---

## Why ECS Tasks Live in Private Subnets

ECS tasks should not be directly reachable from the internet.

Instead:

```text
Internet → ALB → ECS Tasks
```

This provides:

* isolation
* reduced attack surface
* centralized traffic control
* security group filtering

---

## Why NAT Gateway Is Still Required

Even though traffic enters through the ALB, ECS tasks still need outbound internet access for:

* pulling container images from GHCR
* telemetry/exporters
* package downloads
* external APIs
* updates

Private subnets cannot reach the internet directly.

The NAT Gateway provides controlled outbound internet access while keeping ECS tasks private.

Important distinction:

* ALB = inbound traffic
* NAT Gateway = outbound internet access

---

# FastAPI Containerization

The application uses:

* Python 3.12
* FastAPI
* Uvicorn
* uv package manager
* Docker multi-layer image build strategy

The application runs on:

```text
0.0.0.0:8000
```

Important runtime concepts:

* `0.0.0.0` means the container listens on all interfaces
* ECS + ALB communicate using the container port
* The ALB listener port does NOT need to match the container port

Example:

```text
ALB listener :80
↓
Target Group :8000
↓
FastAPI container :8000
```

---

# Health Checks

The FastAPI application exposes:

```text
/health
```

Example response:

```json
{
  "status": "healthy",
  "service": "fastapi-app",
  "version": "1.0.0",
  "environment": "dev",
  "uptime_seconds": 120,
  "timestamp_utc": "2026-05-15T10:22:11Z"
}
```

This endpoint intentionally avoids:

* database queries
* external API calls
* expensive computations

The purpose of this endpoint is:

```text
Process-level operational health
```

NOT:

```text
Full business validation
```

This endpoint is used by:

* ALB health checks
* ECS target health validation
* CI smoke tests

---

# CI/CD Pipeline

The repository includes a GitHub Actions pipeline that:

1. Validates Python source code
2. Runs Ruff linting
3. Validates formatting
4. Verifies FastAPI imports correctly
5. Builds Docker image
6. Runs container smoke test
7. Pushes immutable image artifact to GHCR

---

# Container Smoke Testing

The pipeline performs runtime-level validation by:

* starting the built container
* polling `/health`
* validating successful HTTP responses
* failing pipeline if container never becomes healthy

This validates:

* container startup
* uvicorn runtime
* networking
* port exposure
* FastAPI boot process
* missing runtime files

Important operational lesson:

The pipeline validates the SAME artifact that later gets deployed.

```text
Build once → validate → publish
```

---

# GitHub Container Registry (GHCR)

The CI pipeline publishes container images into GHCR.

Example image:

```text
ghcr.io/<github-user>/fastapi1:<git-sha>
```

Images are tagged using immutable Git commit SHAs for traceability.

This provides:

* deterministic deployments
* rollback safety
* deployment traceability
* artifact reproducibility

---

# ECS Runtime Flow

Container deployment flow:

```text
GitHub Actions
↓
Build container image
↓
Push image to GHCR
↓
ECS Task pulls image through NAT Gateway
↓
Container starts inside private subnet
↓
ALB forwards traffic to ECS tasks
```

---

# Infrastructure as Code

Infrastructure is fully managed with Terraform.

Main AWS resources:

* VPC
* Public Subnets
* Private Subnets
* Internet Gateway
* NAT Gateways
* Route Tables
* Security Groups
* ECS Cluster
* ECS Service
* ECS Task Definition
* Application Load Balancer
* CloudWatch Logs
* IAM Roles
* RDS

---

# Security Model

The architecture follows several important security principles:

## ECS Tasks Are Private

Tasks do not receive public IPs.

---

## Security Group Isolation

Only the ALB security group can reach ECS task ports.

---

## Immutable Containers

Containers are treated as immutable deployment artifacts.

---

## No Secrets Baked Into Images

Container images should never contain:

* AWS credentials
* `.env` files
* API secrets
* database passwords

Secrets should be injected at runtime.

---

# Operational Concepts Learned

This project intentionally focuses on understanding the operational WHY behind cloud-native infrastructure.

Important concepts explored:

* why ALBs live in public subnets
* why ECS tasks live in private subnets
* why NAT Gateways are still required
* how ECS pulls images from external registries
* health checks vs business validation
* polling vs fixed sleeps in CI/CD
* immutable image tagging
* runtime validation vs source validation
* container lifecycle management
* infrastructure layering
* state-aware automation

---

# Future Improvements

Possible next evolution steps:

* ECS rolling deployment automation
* ECS blue/green deployments
* HTTPS with ACM
* Route53 custom domains
* ECR migration
* OpenTelemetry collector sidecar
* Grafana Cloud dashboards
* Terraform modularization
* Multi-environment deployment strategy
* GitHub OIDC → AWS IAM federation
* Autoscaling policies
* WAF integration

---

# Local Development

## Run FastAPI Locally

```bash
uv run uvicorn main:app --host 0.0.0.0 --port 8000
```

---

## Build Docker Image

```bash
docker build --platform linux/amd64 -t fastapi1:latest .
```

---

## Run Container

```bash
docker run -p 8000:8000 fastapi1:latest
```

---

## Test Health Endpoint

```bash
curl http://localhost:8000/health
```

---

# Important Learning Note

This repository is intentionally built as a production-style architecture.

The objective is not merely deploying a FastAPI application, but understanding:

```text
How real cloud systems behave operationally
```

including:

* networking boundaries
* runtime lifecycle
* deployment flow
* container orchestration
* CI/CD artifact management
* infrastructure behavior
* operational tradeoffs
