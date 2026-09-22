# Event-Driven Order Processing Platform

## Solution Overview

The Event-Driven Order Processing Platform provides a containerized backend for an online ordering application. It uses three microservices to handle authentication, order management, and notifications, with asynchronous event processing to keep services loosely coupled.

The platform is designed for high availability, scalability, secure communication, persistent data storage, and centralized monitoring. Infrastructure is managed with Terraform, while GitHub Actions automates container builds and ECS deployments using blue/green releases.

## Microservices

* **Auth Service:** Handles user authentication, authorization, and session management.
* **Orders Service:** Handles creating, retrieving, updating, and managing user orders.
* **Notifications Service:** Processes notification events and publishes notifications to subscribed delivery channels.

## AWS Services

### Networking & Application Access

* Amazon VPC
* Internet Gateway
* NAT Gateway
* Application Load Balancer
* Amazon Route 53
* AWS WAF
* AWS Certificate Manager

### Compute & Containers

* Amazon ECS
* AWS Fargate
* Amazon ECR

### Service Communication & Events

* AWS Cloud Map
* Amazon EventBridge
* Amazon SQS
* Amazon SNS

### Data & Secrets

* Amazon RDS for PostgreSQL
* Amazon ElastiCache for Redis
* AWS Secrets Manager

### Monitoring & Tracing

* Amazon CloudWatch
* AWS X-Ray

## Architecture

![Architecture Diagram](diagrams/architecure.jpg)

### Architecture Explanation

#### 1. Network & Secure Entry

The application runs inside an Amazon VPC spanning two Availability Zones. Each AZ contains a public subnet and a private subnet.

The public subnets contain the internet-facing ALB and a NAT Gateway. The Internet Gateway provides connectivity between the VPC and the internet, while the NAT Gateways allow resources in the private subnets to make outbound internet connections without exposing them directly to the internet.

Amazon Route 53 provides the application domain and resolves it to the ALB. The client then sends an HTTPS request to the ALB.

AWS WAF protects the ALB by filtering incoming web requests. AWS ACM provides the TLS certificate used by the ALB HTTPS listener.

The Auth, Orders, and Notifications Fargate Tasks run in the private subnets across both AZs, keeping the application workloads isolated from direct internet access.

#### 2. Routing

The Application Load Balancer uses path-based routing to send requests to the correct microservice.

For example:

* `/api/auth` → Auth TG
* `/api/orders` → Orders TG
* `/api/notifications` → Notifications TG

Each target group routes requests to the corresponding Fargate Tasks. ALB health checks help ensure that traffic is sent only to healthy tasks.

#### 3. ECS & Fargate

Amazon ECS organizes and manages the Auth, Orders, and Notifications services. Each service maintains its required number of Fargate Tasks.

AWS Fargate runs the containers without requiring us to manage the underlying servers. The tasks are placed across the private subnets in both Availability Zones to improve availability and allow the services to scale.

Amazon ECR stores the Docker images used by the ECS services.

#### 4. Service Discovery

AWS Cloud Map provides private service discovery between the microservices. It is used because Fargate Tasks can be replaced or scaled, so services should not depend on fixed task IP addresses.

Each ECS Service is registered with a Cloud Map service and receives a private DNS name such as `auth.myapp.local`, `orders.myapp.local`, and `notifications.myapp.local`.

For example, the Orders Service can use `auth.myapp.local` to communicate with the Auth Service.

#### 5. Data, Sessions & Secrets

Amazon RDS for PostgreSQL provides persistent storage for application data. The Auth Service uses it for user and account data, while the Orders Service uses it for order data.

Amazon ElastiCache for Redis provides a shared session store for the microservices. Session data is kept outside the Fargate Tasks so the services remain stateless and any task can access the required session information.

AWS Secrets Manager stores sensitive values such as database credentials and API keys. The ECS services retrieve the secrets they need at runtime instead of storing them in the source code or container images.

#### 6. Observability

Amazon CloudWatch provides centralized logs, metrics, and monitoring for the application and infrastructure.

AWS X-Ray provides distributed tracing across the microservices. It helps trace requests between services and makes it easier to find latency or failures.

---

## Event-Driven Order Processing

![Event-driven Diagram](diagrams/event-driven-diagram.jpg)

### Event Flow Explanation

#### 1. Order Event Creation

When an authenticated user creates an order, the request is handled by the Orders Service.

The Orders Service validates and stores the order in Amazon RDS for PostgreSQL. After the order is created, the service publishes an `OrderCreated` event to Amazon EventBridge.

EventBridge is used here so the Orders Service does not need to directly depend on the Notifications Service.

#### 2. Event Routing

Amazon EventBridge receives the `OrderCreated` event and checks it against the configured event rules.

The matching rule sends the event to the Notifications SQS queue. This separates the Orders Service from the notification processing system.

#### 3. Asynchronous Processing

Amazon SQS provides a durable queue between the Orders Service and Notifications Service.

The Notifications Service polls the queue and processes the messages independently. This allows notification processing to continue separately from order creation and helps handle temporary delays or increases in traffic.

A dead-letter queue can be used for messages that repeatedly fail processing.

#### 4. Notification Processing

The Notifications Service receives the order event from SQS and decides what notification should be sent.

After processing the event, the service publishes the notification to the Order Notifications SNS topic.

#### 5. Notification Fan-Out

Amazon SNS distributes the notification to multiple subscribers.

The topic can be connected to different notification channels, such as **Email, SMS, and Mobile notifications**.

This allows the Notifications Service to publish one notification while SNS handles delivery to the configured subscribers.

---

## CI/CD & Blue/Green Deployment

![CI/CD Diagram](diagrams/cicd-blue-green.jpg)

### CI/CD Explanation

#### 1. Continuous Integration

The process starts when a developer pushes code to the GitHub repository.

The push triggers a GitHub Actions workflow that:

* Runs application tests
* Builds the application
* Builds the Docker image
* Pushes the container image to Amazon ECR

#### 2. Container Image Registry

Amazon ECR stores the container images produced by the CI pipeline.

The image is versioned so the correct application version can be referenced by the ECS Task Definition used for deployment.

#### 3. ECS Deployment

After the new image is pushed to ECR, GitHub Actions registers a new ECS Task Definition revision that references the new image.

The new Task Definition revision is then used to update the ECS Service and start the deployment.

#### 4. Blue/Green Deployment

The ECS Service uses the native ECS blue/green deployment strategy.

The current version continues running as the **Blue** revision while ECS creates the new **Green** revision using the updated Task Definition.

The Green Tasks are registered with the alternate target group and can be tested before production traffic is moved to the new version.

This allows both versions to run at the same time during the deployment.

#### 5. Traffic Shift & Validation

The Application Load Balancer uses a production listener rule for production traffic and an optional test listener rule for testing the Green revision.

After the Green revision is ready, ECS shifts production traffic from the Blue Target Group to the Green Target Group. After the configured bake time, the old Blue revision can be removed.

This allows the new version to be tested before it becomes the production version and keeps the previous version available during the deployment.

---

## Infrastructure as Code

The AWS infrastructure is managed using **Terraform**. Keeping the infrastructure as code makes the environment easier to reproduce, review, and update.

The complete Terraform configuration is available in the repository.

### Terraform Deployment

The infrastructure can be initialized, reviewed, and applied with:

```bash
terraform init
terraform plan
terraform apply
```

After applying the configuration, the AWS Console can be used to verify the created resources.

A Terraform apply result such as:

```text
Apply complete! Resources: XX added, 0 changed, 0 destroyed.
```

can be used as proof that Terraform successfully created the infrastructure.
