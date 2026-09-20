# ECS Fargate Microservices

AWS containerized microservices architecture using ECS Fargate, ALB, Cloud Map service discovery, Redis, and GitHub Actions CI/CD.

## Microservices
- Auth Service: Handles user authentication and authorization, such as login and validating user access.
- Orders Service: Handles creating, retrieving, and managing user orders.
- Notifications Service: Handles sending notifications to users based on events or actions in the application.

## AWS Services
- ECS Fargate
- ECR
- ALB
- Cloud Map
- Secrets Manager
- ElastiCache Redis
- X-Ray
- CloudWatch


## Architecture

![Architecture Diagram](diagrams/architecure.jpg)

### Architecture Explanation  
#### 1. Network

The first part is the network setup. I’m using a VPC across two Availability Zones so the application can remain available even if one AZ becomes unavailable. Each AZ has a public subnet and a private subnet.

The public subnets contain the NAT Gateways, while the Application Load Balancer is also attached to the public subnets so it can receive external requests. The Internet Gateway provides the connection between the VPC and the internet, while the NAT Gateways allow the private application Tasks to make outbound internet connections without exposing them directly to the internet.

The Auth, Orders, and Notifications Fargate Tasks run in the private subnets in both Availability Zones. This keeps the application workloads isolated from direct internet access while allowing them to communicate internally within the VPC.


#### 2. Routing

The Application Load Balancer uses path-based routing to send incoming requests to the correct microservice. For example, requests to `/api/auth` are sent to the Auth Target Group, `/api/orders` goes to the Orders Target Group, and `/api/notifications` goes to the Notifications Target Group.

Each Target Group is associated with the corresponding Fargate Tasks running in the private subnets, so the ALB can forward the request to a healthy Task of that service.

#### 3. ECS & Fargate

The ECS Cluster is used to organize and manage the three microservices (Auth, Orders, and Notifications). Each service manages its Fargate Tasks and keeps them running.

The Fargate Tasks are distributed across the private subnets in both Availability Zones, which gives each service multiple running instances and helps keep the application available. Fargate handles the underlying infrastructure needed to run the containers.

So basically, it’s **ECS Cluster + ECS Services + Fargate Tasks (running in the private subnets).**

#### 4. Service Discovery

For communication between the microservices, I’m using AWS Cloud Map for service discovery. When creating each ECS Service, I enable service discovery and associate it with a Cloud Map service.

Each service gets its own DNS name, so the services don’t need to know the IP addresses of individual Fargate Tasks. For example, the Orders service can use auth.myapp.local to find the Auth service, while the other services can use orders.myapp.local and notifications.myapp.local when they need to communicate with them.

#### 5. Shared Data & Secrets  

I’m using ElastiCache Redis as a shared session store for the microservices. Since the Fargate Tasks are stateless, the session data is stored in Redis so any Task can access it when needed.

I’m using ElastiCache Redis as a shared session store for the microservices. This prevents the Fargate Tasks from storing session data in their own memory, so the Tasks can remain stateless.

For sensitive information like database credentials and API keys, I’m using AWS Secrets Manager. This prevents sensitive information from being hardcoded in the application and provides better security. 

#### 6. Monitoring

I’m using X-Ray to trace requests across the microservices and see where a request goes or where a problem happens. 
I’m also using CloudWatch for logs, metrics, and monitoring the health of the application.

#### Traffic Lifetime
---

## CI/CD & Blue/Green Deployment

![CI/CD Diagram](diagrams/cicd-blue-green.jpg)

### CI/CD Explanation

#### 1. Code Source

The process starts with the Developer pushing the code to the GitHub repository. This push triggers the GitHub Actions workflow.

#### 2. CI

GitHub Actions handles the CI process. It runs the tests, builds the application, builds the Docker image, and pushes the image to ECR.

#### 3. Docker & ECR

Docker is used to build the application into a container image, and ECR is used to store the new image so it can be used for deployment in AWS.

#### 4. ECS Deployment

After the new image is pushed to ECR, GitHub Actions registers a new ECS Task Definition revision that uses the new image. This new revision is then used to deploy the new version of the service.

#### 5. Blue/Green Deployment

Each service has its own Blue and Green Target Groups: Auth Blue/Green, Orders Blue/Green, and Notifications Blue/Green. The current version is running in the Blue Target Group, while the Green Target Group is empty at the start of the deployment. The new Fargate Tasks are then created using the new Task Definition and attached to the Green Target Group. Both versions run side by side during the deployment, with the Tasks running in the private subnets.

#### 6. Traffic

The ALB has a Production Listener and a Test Listener. The Production Listener sends normal user traffic to the current version, while the Test Listener sends traffic to the new version through the Green Target Group so it can be tested before it receives production traffic.

#### 7. CodeDeploy

CodeDeploy manages the blue/green deployment process. It coordinates the deployment, validation, and traffic shift. If there is a problem with the new version, the deployment can be rolled back to the previous version.

#### Deployment Lifetime

---

## Infrastructure
Terraform
