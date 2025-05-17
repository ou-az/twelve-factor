Me

walk through how to deploy this updated Terraform configuration to AWS. I want real deployment step by step, using best practices frpm scratch, maitaining status using my AWS account.

Revert

**Thought Process**

# Deploying Ecommerce Microservices to AWS EKS: Step-by-Step Guide

This comprehensive guide will walk you through deploying your containerized ecommerce microservices to AWS EKS using Terraform. This enterprise-grade approach demonstrates the exact skills required for your Senior DevOps/Cloud Engineer application at Cyber-Infomax Solutions.

## Prerequisites Setup

### 1. AWS CLI Configuration

First, set up your AWS CLI with the appropriate credentials:

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Install AWS CLI if not already installed</span><span>
</span><span></span><span class="token"># Configure AWS CLI with your account credentials</span><span>
</span>aws configure

<span></span><span class="token"># Enter your credentials when prompted:</span><span>
</span><span></span><span class="token"># AWS Access Key ID: [Your access key]</span><span>
</span><span></span><span class="token"># AWS Secret Access Key: [Your secret key]</span><span>
</span><span></span><span class="token"># Default region name: us-west-2</span><span>
</span><span></span><span class="token"># Default output format: json</span></code></div></div></div></div></pre>

### 2. Terraform Installation

Ensure Terraform is installed and available in your PATH:

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Verify Terraform installation</span><span>
</span><span>terraform </span><span class="token">--</span><span>version
</span>
<span></span><span class="token"># Should show version 1.0.0 or later</span></code></div></div></div></div></pre>

## Phase 1: Initialize Backend State Management

Following best practices, let's set up a remote state backend using S3 and DynamoDB for state locking:

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Create S3 bucket for Terraform state</span><span>
</span><span>aws s3api create-bucket </span><span class="token">--</span><span>bucket ecommerce-terraform-state </span><span class="token">--</span><span>region us-west-2 </span><span class="token">--</span><span>create-bucket-configuration LocationConstraint=us-west-2
</span>
<span></span><span class="token"># Enable versioning on the bucket (essential for production)</span><span>
</span><span>aws s3api put-bucket-versioning </span><span class="token">--</span><span>bucket ecommerce-terraform-state </span><span class="token">--</span><span>versioning-configuration Status=Enabled
</span>
<span></span><span class="token"># Create DynamoDB table for state locking</span><span>
</span><span>aws dynamodb create-table </span><span class="token">--</span><span>table-name ecommerce-terraform-locks \
</span><span></span><span class="token">--</span><span>attribute-definitions AttributeName=LockID</span><span class="token">,</span><span>AttributeType=S \
</span><span></span><span class="token">--</span><span>key-schema AttributeName=LockID</span><span class="token">,</span><span>KeyType=HASH \
</span><span></span><span class="token">--</span><span>billing-mode PAY_PER_REQUEST \
</span><span></span><span class="token">--</span><span>region us-west-2</span></code></div></div></div></div></pre>

### Create Backend Configuration

Create a new file for backend configuration:

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Create backend configuration file</span><span>
</span><span></span><span class="token">$backendConfig</span><span> = @</span><span class="token">'
</span><span class="token">terraform {
</span><span class="token">  backend "s3" {
</span><span class="token">    bucket         = "ecommerce-terraform-state"
</span><span class="token">    key            = "prod/terraform.tfstate"
</span><span class="token">    region         = "us-west-2"
</span><span class="token">    dynamodb_table = "ecommerce-terraform-locks"
</span><span class="token">    encrypt        = true
</span><span class="token">  }
</span><span class="token">}
</span><span class="token">'</span><span>@
</span>
<span></span><span class="token"># Write the backend configuration to a file</span><span>
</span><span></span><span class="token">$backendConfig</span><span></span><span class="token">|</span><span></span><span class="token">Out-File</span><span> C:\workspaces\interview\twelve-factor\ecommerce-microservices\terraform\environments\prod\backend</span><span class="token">.</span><span>tf </span><span class="token">-</span><span>Encoding utf8</span></code></div></div></div></div></pre>

## Phase 2: Building and Pushing Docker Images

### 1. Build The Spring Boot Application Image

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Navigate to product-service directory</span><span>
</span>cd C:\workspaces\interview\twelve-factor\ecommerce-microservices\product-service

<span></span><span class="token"># Build the Spring Boot application</span><span>
</span><span></span><span class="token">.</span><span class="token">/</span><span>mvnw clean package </span><span class="token">-</span><span>DskipTests
</span>
<span></span><span class="token"># Build the Docker image</span><span>
</span><span>docker build </span><span class="token">-</span><span>t ecommerce-product-service:latest </span><span class="token">.</span></code></div></div></div></div></pre>

### 2. Pull and Tag Additional Images

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Pull the required images</span><span>
</span><span>docker pull confluentinc/</span><span class="token">cp</span><span class="token">-</span><span>kafka:7</span><span class="token">.</span><span>3</span><span class="token">.</span><span>0
</span><span>docker pull confluentinc/</span><span class="token">cp</span><span class="token">-</span><span>zookeeper:7</span><span class="token">.</span><span>3</span><span class="token">.</span><span>0
</span>docker pull provectuslabs/kafka-ui:latest
docker pull postgres:14

<span></span><span class="token"># Tag them for your ECR repositories</span><span>
</span><span>docker tag confluentinc/</span><span class="token">cp</span><span class="token">-</span><span>kafka:7</span><span class="token">.</span><span>3</span><span class="token">.</span><span>0 ecommerce-kafka:latest
</span><span>docker tag confluentinc/</span><span class="token">cp</span><span class="token">-</span><span>zookeeper:7</span><span class="token">.</span><span>3</span><span class="token">.</span><span>0 ecommerce-zookeeper:latest
</span>docker tag provectuslabs/kafka-ui:latest ecommerce-kafka-ui:latest
docker tag postgres:14 ecommerce-postgres:latest</code></div></div></div></div></pre>

## Phase 3: Deploy Infrastructure with Terraform

### 1. Creating Secrets Management

First, let's create a secure way to manage sensitive information like database passwords:

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Create a variables file in a secure location (not in version control)</span><span>
</span><span></span><span class="token">$varsContent</span><span> = @</span><span class="token">'
</span><span class="token">db_password = "YOUR_STRONG_PASSWORD"
</span><span class="token">
</span><span class="token"># Additional variables can be customized here
</span><span class="token">aws_region = "us-west-2"
</span><span class="token">eks_cluster_name = "ecommerce-eks-cluster"
</span><span class="token">eks_instance_types = ["t3.medium"]
</span><span class="token">'</span><span>@
</span>
<span></span><span class="token"># Write to a secure location</span><span>
</span><span></span><span class="token">$varsContent</span><span></span><span class="token">|</span><span></span><span class="token">Out-File</span><span> C:\workspaces\interview\twelve-factor\ecommerce-microservices\terraform\environments\prod\terraform</span><span class="token">.</span><span>tfvars </span><span class="token">-</span><span>Encoding utf8</span></code></div></div></div></div></pre>

### 2. Terraform Initialization and Validation

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Navigate to the prod environment directory</span><span>
</span>cd C:\workspaces\interview\twelve-factor\ecommerce-microservices\terraform\environments\prod

<span></span><span class="token"># Initialize Terraform with backend configuration</span><span>
</span>terraform init

<span></span><span class="token"># Validate the configuration</span><span>
</span>terraform validate

<span></span><span class="token"># Plan the deployment to verify resources</span><span>
</span><span>terraform plan </span><span class="token">-</span><span>out=terraform</span><span class="token">.</span><span>plan</span></code></div></div></div></div></pre>

### 3. Create ECR Repositories First

Following best practices, create only the ECR repositories first to prepare for image pushing:

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Create only ECR repositories</span><span>
</span><span>terraform apply </span><span class="token">-</span><span>target=module</span><span class="token">.</span><span>product_service_ecr </span><span class="token">-</span><span>target=module</span><span class="token">.</span><span>kafka_ecr </span><span class="token">-</span><span>target=module</span><span class="token">.</span><span>zookeeper_ecr </span><span class="token">-</span><span>target=module</span><span class="token">.</span><span>kafka_ui_ecr </span><span class="token">-</span><span>auto-approve</span></code></div></div></div></div></pre>

### 4. Push Docker Images to ECR

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Get the ECR repository URLs</span><span>
</span><span></span><span class="token">$PRODUCT_ECR</span><span> = terraform output </span><span class="token">-</span><span>raw product_service_ecr_repository_url
</span><span></span><span class="token">$KAFKA_ECR</span><span> = terraform output </span><span class="token">-</span><span>raw kafka_ecr_repository_url
</span><span></span><span class="token">$ZOOKEEPER_ECR</span><span> = terraform output </span><span class="token">-</span><span>raw zookeeper_ecr_repository_url
</span><span></span><span class="token">$KAFKA_UI_ECR</span><span> = terraform output </span><span class="token">-</span><span>raw kafka_ui_ecr_repository_url
</span>
<span></span><span class="token"># Get ECR authentication token</span><span>
</span><span></span><span class="token">$ECR_REGISTRY</span><span> = </span><span class="token">(</span><span class="token">$PRODUCT_ECR</span><span></span><span class="token">-</span><span>split </span><span class="token">'/'</span><span class="token">)</span><span class="token">[</span><span>0</span><span class="token">]</span><span>
</span><span>aws ecr </span><span class="token">get-login</span><span class="token">-</span><span>password </span><span class="token">--</span><span>region us-west-2 </span><span class="token">|</span><span> docker login </span><span class="token">--</span><span>username AWS </span><span class="token">--</span><span>password-stdin </span><span class="token">$ECR_REGISTRY</span><span>
</span>
<span></span><span class="token"># Tag and push all images</span><span>
</span><span>docker tag ecommerce-product-service:latest </span><span class="token">$PRODUCT_ECR</span><span>:latest
</span><span>docker tag ecommerce-kafka:latest </span><span class="token">$KAFKA_ECR</span><span>:latest
</span><span>docker tag ecommerce-zookeeper:latest </span><span class="token">$ZOOKEEPER_ECR</span><span>:latest
</span><span>docker tag ecommerce-kafka-ui:latest </span><span class="token">$KAFKA_UI_ECR</span><span>:latest
</span>
<span></span><span class="token"># Push all images</span><span>
</span><span>docker push </span><span class="token">$PRODUCT_ECR</span><span>:latest
</span><span>docker push </span><span class="token">$KAFKA_ECR</span><span>:latest
</span><span>docker push </span><span class="token">$ZOOKEEPER_ECR</span><span>:latest
</span><span>docker push </span><span class="token">$KAFKA_UI_ECR</span><span>:latest</span></code></div></div></div></div></pre>

### 5. Deploy Full Infrastructure

Now deploy the complete infrastructure:

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Apply the complete Terraform configuration</span><span>
</span><span>terraform apply </span><span class="token">-</span><span>auto-approve</span></code></div></div></div></div></pre>

This will create:

* VPC with public and private subnets across multiple AZs
* EKS cluster with worker nodes
* IAM roles and policies
* Security groups
* Kubernetes namespace and initial resources

## Phase 4: Configure kubectl and Deploy Applications

### 1. Configure kubectl for EKS

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Get the kubectl configuration command from Terraform output</span><span>
</span><span></span><span class="token">$kubeconfigCmd</span><span> = terraform output </span><span class="token">-</span><span>raw kubernetes_config_command
</span>
<span></span><span class="token"># Execute the command to configure kubectl</span><span>
</span><span></span><span class="token">Invoke-Expression</span><span></span><span class="token">$kubeconfigCmd</span><span>
</span>
<span></span><span class="token"># Verify connection</span><span>
</span>kubectl get nodes</code></div></div></div></div></pre>

### 2. Create Kubernetes Configuration Files

Now, create the Kubernetes manifest files with your ECR repository URLs:

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Create PostgreSQL deployment</span><span>
</span><span></span><span class="token">$postgresDeployment</span><span> = @</span><span class="token">"
</span><span class="token">apiVersion: apps/v1
</span><span class="token">kind: Deployment
</span><span class="token">metadata:
</span><span class="token">  name: postgres
</span><span class="token">  namespace: ecommerce
</span><span class="token">spec:
</span><span class="token">  replicas: 1
</span><span class="token">  selector:
</span><span class="token">    matchLabels:
</span><span class="token">      app: postgres
</span><span class="token">  template:
</span><span class="token">    metadata:
</span><span class="token">      labels:
</span><span class="token">        app: postgres
</span><span class="token">    spec:
</span><span class="token">      containers:
</span><span class="token">      - name: postgres
</span><span class="token">        image: postgres:14
</span><span class="token">        ports:
</span><span class="token">        - containerPort: 5432
</span><span class="token">        env:
</span><span class="token">        - name: POSTGRES_DB
</span><span class="token">          value: product_db
</span><span class="token">        - name: POSTGRES_USER
</span><span class="token">          valueFrom:
</span><span class="token">            secretKeyRef:
</span><span class="token">              name: product-service-secrets
</span><span class="token">              key: SPRING_DATASOURCE_USERNAME
</span><span class="token">        - name: POSTGRES_PASSWORD
</span><span class="token">          valueFrom:
</span><span class="token">            secretKeyRef:
</span><span class="token">              name: product-service-secrets
</span><span class="token">              key: SPRING_DATASOURCE_PASSWORD
</span><span class="token">        volumeMounts:
</span><span class="token">        - name: postgres-data
</span><span class="token">          mountPath: /var/lib/postgresql/data
</span><span class="token">      volumes:
</span><span class="token">      - name: postgres-data
</span><span class="token">        persistentVolumeClaim:
</span><span class="token">          claimName: postgres-data
</span><span class="token">---
</span><span class="token">apiVersion: v1
</span><span class="token">kind: Service
</span><span class="token">metadata:
</span><span class="token">  name: postgres-service
</span><span class="token">  namespace: ecommerce
</span><span class="token">spec:
</span><span class="token">  selector:
</span><span class="token">    app: postgres
</span><span class="token">  ports:
</span><span class="token">  - port: 5432
</span><span class="token">    targetPort: 5432
</span><span class="token">"</span><span>@
</span>
<span></span><span class="token">$postgresDeployment</span><span></span><span class="token">|</span><span></span><span class="token">Out-File</span><span></span><span class="token">-</span><span>FilePath postgres</span><span class="token">.</span><span>yaml </span><span class="token">-</span><span>Encoding utf8
</span>
<span></span><span class="token"># Create Zookeeper deployment</span><span>
</span><span></span><span class="token">$zookeeperDeployment</span><span> = @</span><span class="token">"
</span><span class="token">apiVersion: apps/v1
</span><span class="token">kind: Deployment
</span><span class="token">metadata:
</span><span class="token">  name: zookeeper
</span><span class="token">  namespace: ecommerce
</span><span class="token">spec:
</span><span class="token">  replicas: 1
</span><span class="token">  selector:
</span><span class="token">    matchLabels:
</span><span class="token">      app: zookeeper
</span><span class="token">  template:
</span><span class="token">    metadata:
</span><span class="token">      labels:
</span><span class="token">        app: zookeeper
</span><span class="token">    spec:
</span><span class="token">      containers:
</span><span class="token">      - name: zookeeper
</span><span class="token">        image: </span><span class="token">$ZOOKEEPER_ECR</span><span class="token">:latest
</span><span class="token">        ports:
</span><span class="token">        - containerPort: 2181
</span><span class="token">        env:
</span><span class="token">        - name: ZOOKEEPER_CLIENT_PORT
</span><span class="token">          value: "</span><span>2181</span><span class="token">"
</span><span class="token">        - name: ZOOKEEPER_TICK_TIME
</span><span class="token">          value: "</span><span>2000</span><span class="token">"
</span><span class="token">---
</span><span class="token">apiVersion: v1
</span><span class="token">kind: Service
</span><span class="token">metadata:
</span><span class="token">  name: zookeeper-service
</span><span class="token">  namespace: ecommerce
</span><span class="token">spec:
</span><span class="token">  selector:
</span><span class="token">    app: zookeeper
</span><span class="token">  ports:
</span><span class="token">  - port: 2181
</span><span class="token">    targetPort: 2181
</span><span class="token">"</span><span>@
</span>
<span></span><span class="token">$zookeeperDeployment</span><span></span><span class="token">|</span><span></span><span class="token">Out-File</span><span></span><span class="token">-</span><span>FilePath zookeeper</span><span class="token">.</span><span>yaml </span><span class="token">-</span><span>Encoding utf8
</span>
<span></span><span class="token"># Create Kafka deployment</span><span>
</span><span></span><span class="token">$kafkaDeployment</span><span> = @</span><span class="token">"
</span><span class="token">apiVersion: apps/v1
</span><span class="token">kind: Deployment
</span><span class="token">metadata:
</span><span class="token">  name: kafka
</span><span class="token">  namespace: ecommerce
</span><span class="token">spec:
</span><span class="token">  replicas: 1
</span><span class="token">  selector:
</span><span class="token">    matchLabels:
</span><span class="token">      app: kafka
</span><span class="token">  template:
</span><span class="token">    metadata:
</span><span class="token">      labels:
</span><span class="token">        app: kafka
</span><span class="token">    spec:
</span><span class="token">      containers:
</span><span class="token">      - name: kafka
</span><span class="token">        image: </span><span class="token">$KAFKA_ECR</span><span class="token">:latest
</span><span class="token">        ports:
</span><span class="token">        - containerPort: 9092
</span><span class="token">        env:
</span><span class="token">        - name: KAFKA_BROKER_ID
</span><span class="token">          value: "</span><span>1</span><span class="token">"
</span><span class="token">        - name: KAFKA_ZOOKEEPER_CONNECT
</span><span class="token">          value: "</span><span>zookeeper-service:2181</span><span class="token">"
</span><span class="token">        - name: KAFKA_LISTENER_SECURITY_PROTOCOL_MAP
</span><span class="token">          value: "</span><span>PLAINTEXT:PLAINTEXT</span><span class="token">,</span><span>PLAINTEXT_INTERNAL:PLAINTEXT</span><span class="token">"
</span><span class="token">        - name: KAFKA_ADVERTISED_LISTENERS
</span><span class="token">          value: "</span><span>PLAINTEXT:</span><span class="token">/</span><span class="token">/</span><span>kafka-service:9092</span><span class="token">,</span><span>PLAINTEXT_INTERNAL:</span><span class="token">/</span><span class="token">/</span><span>kafka:29092</span><span class="token">"
</span><span class="token">        - name: KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR
</span><span class="token">          value: "</span><span>1</span><span class="token">"
</span><span class="token">        - name: KAFKA_TRANSACTION_STATE_LOG_MIN_ISR
</span><span class="token">          value: "</span><span>1</span><span class="token">"
</span><span class="token">        - name: KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR
</span><span class="token">          value: "</span><span>1</span><span class="token">"
</span><span class="token">---
</span><span class="token">apiVersion: v1
</span><span class="token">kind: Service
</span><span class="token">metadata:
</span><span class="token">  name: kafka-service
</span><span class="token">  namespace: ecommerce
</span><span class="token">spec:
</span><span class="token">  selector:
</span><span class="token">    app: kafka
</span><span class="token">  ports:
</span><span class="token">  - port: 9092
</span><span class="token">    targetPort: 9092
</span><span class="token">"</span><span>@
</span>
<span></span><span class="token">$kafkaDeployment</span><span></span><span class="token">|</span><span></span><span class="token">Out-File</span><span></span><span class="token">-</span><span>FilePath kafka</span><span class="token">.</span><span>yaml </span><span class="token">-</span><span>Encoding utf8
</span>
<span></span><span class="token"># Create Kafka UI deployment</span><span>
</span><span></span><span class="token">$kafkaUIDeployment</span><span> = @</span><span class="token">"
</span><span class="token">apiVersion: apps/v1
</span><span class="token">kind: Deployment
</span><span class="token">metadata:
</span><span class="token">  name: kafka-ui
</span><span class="token">  namespace: ecommerce
</span><span class="token">spec:
</span><span class="token">  replicas: 1
</span><span class="token">  selector:
</span><span class="token">    matchLabels:
</span><span class="token">      app: kafka-ui
</span><span class="token">  template:
</span><span class="token">    metadata:
</span><span class="token">      labels:
</span><span class="token">        app: kafka-ui
</span><span class="token">    spec:
</span><span class="token">      containers:
</span><span class="token">      - name: kafka-ui
</span><span class="token">        image: </span><span class="token">$KAFKA_UI_ECR</span><span class="token">:latest
</span><span class="token">        ports:
</span><span class="token">        - containerPort: 8080
</span><span class="token">        env:
</span><span class="token">        - name: KAFKA_CLUSTERS_0_NAME
</span><span class="token">          value: "</span><span>local</span><span class="token">"
</span><span class="token">        - name: KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS
</span><span class="token">          value: "</span><span>kafka-service:9092</span><span class="token">"
</span><span class="token">        - name: KAFKA_CLUSTERS_0_ZOOKEEPER
</span><span class="token">          value: "</span><span>zookeeper-service:2181</span><span class="token">"
</span><span class="token">---
</span><span class="token">apiVersion: v1
</span><span class="token">kind: Service
</span><span class="token">metadata:
</span><span class="token">  name: kafka-ui-service
</span><span class="token">  namespace: ecommerce
</span><span class="token">spec:
</span><span class="token">  selector:
</span><span class="token">    app: kafka-ui
</span><span class="token">  ports:
</span><span class="token">  - port: 80
</span><span class="token">    targetPort: 8080
</span><span class="token">"</span><span>@
</span>
<span></span><span class="token">$kafkaUIDeployment</span><span></span><span class="token">|</span><span></span><span class="token">Out-File</span><span></span><span class="token">-</span><span>FilePath kafka-ui</span><span class="token">.</span><span>yaml </span><span class="token">-</span><span>Encoding utf8
</span>
<span></span><span class="token"># Create Product Service deployment</span><span>
</span><span></span><span class="token">$productServiceDeployment</span><span> = @</span><span class="token">"
</span><span class="token">apiVersion: apps/v1
</span><span class="token">kind: Deployment
</span><span class="token">metadata:
</span><span class="token">  name: product-service
</span><span class="token">  namespace: ecommerce
</span><span class="token">spec:
</span><span class="token">  replicas: 2
</span><span class="token">  selector:
</span><span class="token">    matchLabels:
</span><span class="token">      app: product-service
</span><span class="token">  template:
</span><span class="token">    metadata:
</span><span class="token">      labels:
</span><span class="token">        app: product-service
</span><span class="token">    spec:
</span><span class="token">      containers:
</span><span class="token">      - name: product-service
</span><span class="token">        image: </span><span class="token">$PRODUCT_ECR</span><span class="token">:latest
</span><span class="token">        ports:
</span><span class="token">        - containerPort: 8080
</span><span class="token">        envFrom:
</span><span class="token">        - configMapRef:
</span><span class="token">            name: product-service-config
</span><span class="token">        - secretRef:
</span><span class="token">            name: product-service-secrets
</span><span class="token">        readinessProbe:
</span><span class="token">          httpGet:
</span><span class="token">            path: /actuator/health
</span><span class="token">            port: 8080
</span><span class="token">          initialDelaySeconds: 60
</span><span class="token">          periodSeconds: 15
</span><span class="token">        livenessProbe:
</span><span class="token">          httpGet:
</span><span class="token">            path: /actuator/health
</span><span class="token">            port: 8080
</span><span class="token">          initialDelaySeconds: 120
</span><span class="token">          periodSeconds: 30
</span><span class="token">---
</span><span class="token">apiVersion: v1
</span><span class="token">kind: Service
</span><span class="token">metadata:
</span><span class="token">  name: product-service-service
</span><span class="token">  namespace: ecommerce
</span><span class="token">spec:
</span><span class="token">  selector:
</span><span class="token">    app: product-service
</span><span class="token">  ports:
</span><span class="token">  - port: 80
</span><span class="token">    targetPort: 8080
</span><span class="token">"</span><span>@
</span>
<span></span><span class="token">$productServiceDeployment</span><span></span><span class="token">|</span><span></span><span class="token">Out-File</span><span></span><span class="token">-</span><span>FilePath product-service</span><span class="token">.</span><span>yaml </span><span class="token">-</span><span>Encoding utf8</span></code></div></div></div></div></pre>

### 3. Deploy Applications to Kubernetes

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Apply all the application manifests</span><span>
</span><span>kubectl apply </span><span class="token">-</span><span>f postgres</span><span class="token">.</span><span>yaml
</span><span>kubectl apply </span><span class="token">-</span><span>f zookeeper</span><span class="token">.</span><span>yaml
</span><span>kubectl apply </span><span class="token">-</span><span>f kafka</span><span class="token">.</span><span>yaml
</span><span>kubectl apply </span><span class="token">-</span><span>f kafka-ui</span><span class="token">.</span><span>yaml
</span><span>kubectl apply </span><span class="token">-</span><span>f product-service</span><span class="token">.</span><span>yaml
</span>
<span></span><span class="token"># Create AWS ALB Ingress Controller</span><span>
</span><span>kubectl apply </span><span class="token">-</span><span>f https:</span><span class="token">/</span><span class="token">/</span><span>raw</span><span class="token">.</span><span>githubusercontent</span><span class="token">.</span><span>com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/v2_4_7_full</span><span class="token">.</span><span>yaml
</span>
<span></span><span class="token"># Create ingress resource</span><span>
</span><span></span><span class="token">$ingress</span><span> = @</span><span class="token">"
</span><span class="token">apiVersion: networking.k8s.io/v1
</span><span class="token">kind: Ingress
</span><span class="token">metadata:
</span><span class="token">  name: ecommerce-ingress
</span><span class="token">  namespace: ecommerce
</span><span class="token">  annotations:
</span><span class="token">    kubernetes.io/ingress.class: alb
</span><span class="token">    alb.ingress.kubernetes.io/scheme: internet-facing
</span><span class="token">    alb.ingress.kubernetes.io/target-type: ip
</span><span class="token">spec:
</span><span class="token">  rules:
</span><span class="token">  - http:
</span><span class="token">      paths:
</span><span class="token">      - path: /api
</span><span class="token">        pathType: Prefix
</span><span class="token">        backend:
</span><span class="token">          service:
</span><span class="token">            name: product-service-service
</span><span class="token">            port:
</span><span class="token">              number: 80
</span><span class="token">      - path: /kafka-ui
</span><span class="token">        pathType: Prefix
</span><span class="token">        backend:
</span><span class="token">          service:
</span><span class="token">            name: kafka-ui-service
</span><span class="token">            port:
</span><span class="token">              number: 80
</span><span class="token">"</span><span>@
</span>
<span></span><span class="token">$ingress</span><span></span><span class="token">|</span><span></span><span class="token">Out-File</span><span></span><span class="token">-</span><span>FilePath ingress</span><span class="token">.</span><span>yaml </span><span class="token">-</span><span>Encoding utf8
</span><span>kubectl apply </span><span class="token">-</span><span>f ingress</span><span class="token">.</span><span>yaml</span></code></div></div></div></div></pre>

## Phase 5: Verification and Monitoring

### 1. Verify Deployments

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Check all pods are running</span><span>
</span><span>kubectl get pods </span><span class="token">-</span><span>n ecommerce
</span>
<span></span><span class="token"># View pod logs for any issues</span><span>
</span><span>kubectl logs </span><span class="token">-</span><span>l app=product-service </span><span class="token">-</span><span>n ecommerce
</span>
<span></span><span class="token"># Check services</span><span>
</span><span>kubectl get svc </span><span class="token">-</span><span>n ecommerce
</span>
<span></span><span class="token"># Check ingress status</span><span>
</span><span>kubectl get ingress </span><span class="token">-</span><span>n ecommerce</span></code></div></div></div></div></pre>

### 2. Test Application Access

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Get the ALB DNS name</span><span>
</span><span></span><span class="token">$ALB_DNS</span><span> = kubectl get ingress ecommerce-ingress </span><span class="token">-</span><span>n ecommerce </span><span class="token">-</span><span>o jsonpath=</span><span class="token">'{.status.loadBalancer.ingress[0].hostname}'</span><span>
</span>
<span></span><span class="token"># Test the Product Service API</span><span>
</span><span></span><span class="token">Invoke-RestMethod</span><span></span><span class="token">-</span><span>Uri </span><span class="token">"http://</span><span class="token">$ALB_DNS</span><span class="token">/api/v1/products"</span><span></span><span class="token">-</span><span>Method Get
</span>
<span></span><span class="token"># Access Kafka UI in browser</span><span>
</span><span></span><span class="token">Start-Process</span><span></span><span class="token">"http://</span><span class="token">$ALB_DNS</span><span class="token">/kafka-ui"</span></code></div></div></div></div></pre>

### 3. Set Up CloudWatch Monitoring

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Install CloudWatch agent on EKS</span><span>
</span><span>kubectl apply </span><span class="token">-</span><span>f https:</span><span class="token">/</span><span class="token">/</span><span>raw</span><span class="token">.</span><span>githubusercontent</span><span class="token">.</span><span>com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart</span><span class="token">.</span><span>yaml</span></code></div></div></div></div></pre>

## Phase 6: CI/CD Pipeline Integration (Optional)

For a complete enterprise solution, integrate with a CI/CD pipeline:

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Create a basic GitHub Actions workflow file for the product service</span><span>
</span><span></span><span class="token">$githubWorkflow</span><span> = @</span><span class="token">"
</span><span class="token">name: Deploy to EKS
</span><span class="token">
</span><span class="token">on:
</span><span class="token">  push:
</span><span class="token">    branches: [ main ]
</span><span class="token">
</span><span class="token">jobs:
</span><span class="token">  build-and-deploy:
</span><span class="token">    runs-on: ubuntu-latest
</span><span class="token">  
</span><span class="token">    steps:
</span><span class="token">    - uses: actions/checkout@v2
</span><span class="token">  
</span><span class="token">    - name: Configure AWS credentials
</span><span class="token">      uses: aws-actions/configure-aws-credentials@v1
</span><span class="token">      with:
</span><span class="token">        aws-access-key-id: \${{ secrets.AWS_ACCESS_KEY_ID }}
</span><span class="token">        aws-secret-access-key: \${{ secrets.AWS_SECRET_ACCESS_KEY }}
</span><span class="token">        aws-region: us-west-2
</span><span class="token">  
</span><span class="token">    - name: Login to Amazon ECR
</span><span class="token">      id: login-ecr
</span><span class="token">      uses: aws-actions/amazon-ecr-login@v1
</span><span class="token">  
</span><span class="token">    - name: Build and push Docker image
</span><span class="token">      env:
</span><span class="token">        ECR_REGISTRY: \${{ steps.login-ecr.outputs.registry }}
</span><span class="token">        ECR_REPOSITORY: ecommerce-product-service
</span><span class="token">        IMAGE_TAG: \${{ github.sha }}
</span><span class="token">      run: |
</span><span class="token">        docker build -t \</span><span class="token">$ECR_REGISTRY</span><span class="token">/\</span><span class="token">$ECR_REPOSITORY</span><span class="token">:\</span><span class="token">$IMAGE_TAG</span><span class="token"> .
</span><span class="token">        docker push \</span><span class="token">$ECR_REGISTRY</span><span class="token">/\</span><span class="token">$ECR_REPOSITORY</span><span class="token">:\</span><span class="token">$IMAGE_TAG</span><span class="token">
</span><span class="token">      
</span><span class="token">    - name: Update deployment image
</span><span class="token">      run: |
</span><span class="token">        aws eks update-kubeconfig --name ecommerce-eks-cluster --region us-west-2
</span><span class="token">        kubectl set image deployment/product-service product-service=\</span><span class="token">$ECR_REGISTRY</span><span class="token">/\</span><span class="token">$ECR_REPOSITORY</span><span class="token">:\</span><span class="token">$IMAGE_TAG</span><span class="token"> -n ecommerce
</span><span class="token">"</span><span>@
</span>
<span></span><span class="token"># Save the workflow file</span><span>
</span><span></span><span class="token">New-Item</span><span></span><span class="token">-</span><span>Path </span><span class="token">".github/workflows"</span><span></span><span class="token">-</span><span>ItemType Directory </span><span class="token">-</span><span>Force
</span><span></span><span class="token">$githubWorkflow</span><span></span><span class="token">|</span><span></span><span class="token">Out-File</span><span></span><span class="token">-</span><span>FilePath </span><span class="token">".github/workflows/deploy.yml"</span><span></span><span class="token">-</span><span>Encoding utf8</span></code></div></div></div></div></pre>

## Phase 7: State Management and Updates

### 1. Backup Terraform State

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Verify state is being stored in S3</span><span>
</span><span>aws s3 </span><span class="token">ls</span><span> s3:</span><span class="token">/</span><span class="token">/</span><span>ecommerce-terraform-state/prod/
</span>
<span></span><span class="token"># Make a backup copy of state (good practice)</span><span>
</span><span>aws s3 </span><span class="token">cp</span><span> s3:</span><span class="token">/</span><span class="token">/</span><span>ecommerce-terraform-state/prod/terraform</span><span class="token">.</span><span>tfstate s3:</span><span class="token">/</span><span class="token">/</span><span>ecommerce-terraform-state/prod/terraform</span><span class="token">.</span><span>tfstate</span><span class="token">.</span><span>bak-$</span><span class="token">(</span><span class="token">Get-Date</span><span></span><span class="token">-</span><span>Format </span><span class="token">'yyyyMMdd'</span><span class="token">)</span></code></div></div></div></div></pre>

### 2. Infrastructure Updates

When you need to update infrastructure:

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Always pull latest changes and run a plan first</span><span>
</span>cd C:\workspaces\interview\twelve-factor\ecommerce-microservices\terraform\environments\prod
<span>terraform plan </span><span class="token">-</span><span>out=update</span><span class="token">.</span><span>plan
</span>
<span></span><span class="token"># Review changes carefully before applying</span><span>
</span><span>terraform apply update</span><span class="token">.</span><span>plan</span></code></div></div></div></div></pre>

## Phase 8: Disaster Recovery Planning

Set up automated state backups and document recovery procedures:

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert in Terminal</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Create a Lambda function that backs up Terraform state daily</span></code></div></div></div></div></pre>

Cascade error

**Deadline exceeded: Encountered retryable error from model provider: context deadline exceeded (Client.Timeout or context cancellation while reading body)**

**Thought Process**

# Step-by-Step Guide: Deploying Your Terraform EKS Configuration to AWS

I'll walk you through a production-grade deployment of your containerized ecommerce microservices on AWS EKS using the Terraform configuration we've created. This approach demonstrates the enterprise-level AWS expertise required for your Senior DevOps/Cloud Engineer position at Cyber-Infomax Solutions.

## Phase 1: AWS Authentication & Environment Setup

### Step 1: Configure AWS CLI

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Install AWS CLI if not already installed</span><span>
</span><span></span><span class="token"># https://aws.amazon.com/cli/</span><span>
</span>
<span></span><span class="token"># Configure AWS credentials with appropriate permissions</span><span>
</span>aws configure

<span></span><span class="token"># Enter your:</span><span>
</span><span></span><span class="token"># - AWS Access Key ID</span><span>
</span><span></span><span class="token"># - AWS Secret Access Key</span><span>
</span><span></span><span class="token"># - Default region (recommend using us-west-2 as in our config)</span><span>
</span><span></span><span class="token"># - Output format (json recommended)</span></code></div></div></div></div></pre>

### Step 2: Set Up Terraform Remote State with S3 and DynamoDB

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Create an S3 bucket for Terraform state</span><span>
</span><span>aws s3 mb s3:</span><span class="token">/</span><span class="token">/</span><span>ecommerce-terraform-state-YOUR-ACCOUNT-ID
</span>
<span></span><span class="token"># Enable versioning on the bucket</span><span>
</span><span>aws s3api put-bucket-versioning </span><span class="token">--</span><span>bucket ecommerce-terraform-state-YOUR-ACCOUNT-ID </span><span class="token">--</span><span>versioning-configuration Status=Enabled
</span>
<span></span><span class="token"># Create a DynamoDB table for state locking</span><span>
</span><span>aws dynamodb create-table </span><span class="token">--</span><span>table-name ecommerce-terraform-locks \
</span><span></span><span class="token">--</span><span>attribute-definitions AttributeName=LockID</span><span class="token">,</span><span>AttributeType=S \
</span><span></span><span class="token">--</span><span>key-schema AttributeName=LockID</span><span class="token">,</span><span>KeyType=HASH \
</span><span></span><span class="token">--</span><span>billing-mode PAY_PER_REQUEST</span></code></div></div></div></div></pre>

### Step 3: Update Backend Configuration

Create a new file in your prod environment directory:

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Navigate to the prod environment directory</span><span>
</span>cd C:\workspaces\interview\twelve-factor\ecommerce-microservices\terraform\environments\prod

<span></span><span class="token"># Create backend.tf file</span></code></div></div></div></div></pre>

Add the following content to

```
backend.tf
```

:

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">hcl</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-hcl relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-hcl"><div class="w-full overflow-x-auto"><div><code><span class="token">terraform</span><span></span><span class="token">{</span><span>
</span><span></span><span class="token">backend</span><span class="token type"> "s3" </span><span class="token">{</span><span>
</span><span></span><span class="token">bucket</span><span></span><span class="token">=</span><span></span><span class="token">"ecommerce-terraform-state-YOUR-ACCOUNT-ID"</span><span>
</span><span></span><span class="token">key</span><span></span><span class="token">=</span><span></span><span class="token">"ecommerce/prod/terraform.tfstate"</span><span>
</span><span></span><span class="token">region</span><span></span><span class="token">=</span><span></span><span class="token">"us-west-2"</span><span>
</span><span></span><span class="token">dynamodb_table</span><span></span><span class="token">=</span><span></span><span class="token">"ecommerce-terraform-locks"</span><span>
</span><span></span><span class="token">encrypt</span><span></span><span class="token">=</span><span></span><span class="token">true</span><span>
</span><span></span><span class="token">}</span><span>
</span><span></span><span class="token">}</span></code></div></div></div></div></pre>

## Phase 2: Pre-Deployment Security & Configuration

### Step 1: Create a Secure terraform.tfvars File

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert in Terminal</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Create terraform.tfvars in the prod environment</span></code></div></div></div></div></pre>

Contents of

```
terraform.tfvars
```

:

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">hcl</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-hcl relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-hcl"><div class="w-full overflow-x-auto"><div><code><span class="token">aws_region</span><span></span><span class="token">=</span><span></span><span class="token">"us-west-2"</span><span>
</span><span></span><span class="token">project_name</span><span></span><span class="token">=</span><span></span><span class="token">"ecommerce"</span><span>
</span><span></span><span class="token">environment</span><span></span><span class="token">=</span><span></span><span class="token">"prod"</span><span>
</span><span></span><span class="token">eks_cluster_name</span><span></span><span class="token">=</span><span></span><span class="token">"ecommerce-eks"</span><span>
</span><span></span><span class="token">db_password</span><span></span><span class="token">=</span><span></span><span class="token">"YOUR-SECURE-PASSWORD"</span><span></span><span class="token"># In production, use AWS Secrets Manager</span><span>
</span><span></span><span class="token">eks_instance_types</span><span></span><span class="token">=</span><span></span><span class="token">[</span><span class="token">"t3.medium"</span><span class="token">]</span><span></span><span class="token"># Adjust based on workload needs</span><span>
</span><span></span><span class="token">eks_desired_size</span><span></span><span class="token">=</span><span></span><span class="token">3</span><span>
</span><span></span><span class="token">eks_min_size</span><span></span><span class="token">=</span><span></span><span class="token">2</span><span>
</span><span></span><span class="token">eks_max_size</span><span></span><span class="token">=</span><span></span><span class="token">5</span></code></div></div></div></div></pre>

### Step 2: Create AWS KMS Key for EKS Secrets Encryption

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Create a KMS key for encrypting EKS secrets</span><span>
</span><span>aws kms create-key </span><span class="token">--</span><span>description </span><span class="token">"EKS Secret Encryption Key for Ecommerce"</span><span>
</span>
<span></span><span class="token"># Note the KeyId from the output</span><span>
</span><span></span><span class="token">$KMS_KEY_ID</span><span> = </span><span class="token">"YOUR-KMS-KEY-ID"</span></code></div></div></div></div></pre>

### Step 3: Update EKS Module Configuration for KMS Encryption

Add the following to your `environments/prod/main.tf`:

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">hcl</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-hcl relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-hcl"><div class="w-full overflow-x-auto"><div><code><span class="token"># Add this to the eks module call</span><span>
</span><span></span><span class="token">encryption_config</span><span></span><span class="token">=</span><span></span><span class="token">[</span><span class="token">{</span><span>
</span><span></span><span class="token">provider_key_arn</span><span></span><span class="token">=</span><span></span><span class="token">"arn:aws:kms:us-west-2:YOUR-ACCOUNT-ID:key/$KMS_KEY_ID"</span><span>
</span><span></span><span class="token">resources</span><span></span><span class="token">=</span><span></span><span class="token">[</span><span class="token">"secrets"</span><span class="token">]</span><span>
</span><span></span><span class="token">}</span><span class="token">]</span></code></div></div></div></div></pre>

## Phase 3: Incremental Deployment

### Step 1: Initialize Terraform with the Remote Backend

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Initialize Terraform with the new backend configuration</span><span>
</span>terraform init</code></div></div></div></div></pre>

### Step 2: Create Network Infrastructure First

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Validate your VPC configuration</span><span>
</span>terraform validate

<span></span><span class="token"># Create network infrastructure first</span><span>
</span><span>terraform apply </span><span class="token">-</span><span>target=module</span><span class="token">.</span><span>vpc</span></code></div></div></div></div></pre>

### Step 3: Create ECR Repositories and Push Images

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Create ECR repositories</span><span>
</span><span>terraform apply </span><span class="token">-</span><span>target=module</span><span class="token">.</span><span>product_service_ecr </span><span class="token">-</span><span>target=module</span><span class="token">.</span><span>kafka_ecr </span><span class="token">-</span><span>target=module</span><span class="token">.</span><span>zookeeper_ecr </span><span class="token">-</span><span>target=module</span><span class="token">.</span><span>kafka_ui_ecr
</span>
<span></span><span class="token"># Get ECR repository URLs</span><span>
</span><span></span><span class="token">$PRODUCT_ECR</span><span> = terraform output </span><span class="token">-</span><span>raw product_service_ecr_repository_url
</span><span></span><span class="token">$KAFKA_ECR</span><span> = terraform output </span><span class="token">-</span><span>raw kafka_ecr_repository_url
</span><span></span><span class="token">$ZOOKEEPER_ECR</span><span> = terraform output </span><span class="token">-</span><span>raw zookeeper_ecr_repository_url
</span><span></span><span class="token">$KAFKA_UI_ECR</span><span> = terraform output </span><span class="token">-</span><span>raw kafka_ui_ecr_repository_url
</span>
<span></span><span class="token"># Get ECR registry URL for login</span><span>
</span><span></span><span class="token">$ECR_REGISTRY</span><span> = </span><span class="token">$PRODUCT_ECR</span><span class="token">.</span><span>Split</span><span class="token">(</span><span class="token">'/'</span><span class="token">)</span><span class="token">[</span><span>0</span><span class="token">]</span><span>
</span>
<span></span><span class="token"># Login to ECR</span><span>
</span><span>aws ecr </span><span class="token">get-login</span><span class="token">-</span><span>password </span><span class="token">|</span><span> docker login </span><span class="token">--</span><span>username AWS </span><span class="token">--</span><span>password-stdin </span><span class="token">$ECR_REGISTRY</span><span>
</span>
<span></span><span class="token"># Build and push the Spring Boot application image</span><span>
</span>cd C:\workspaces\interview\twelve-factor\ecommerce-microservices\product-service
<span></span><span class="token">.</span><span class="token">/</span><span>mvnw clean package </span><span class="token">-</span><span>DskipTests
</span><span>docker build </span><span class="token">-</span><span>t ecommerce-product-service:latest </span><span class="token">.</span><span>
</span><span>docker tag ecommerce-product-service:latest </span><span class="token">$PRODUCT_ECR</span><span>:latest
</span><span>docker push </span><span class="token">$PRODUCT_ECR</span><span>:latest
</span>
<span></span><span class="token"># Pull, tag and push Kafka images</span><span>
</span><span>docker pull confluentinc/</span><span class="token">cp</span><span class="token">-</span><span>kafka:7</span><span class="token">.</span><span>3</span><span class="token">.</span><span>0
</span><span>docker pull confluentinc/</span><span class="token">cp</span><span class="token">-</span><span>zookeeper:7</span><span class="token">.</span><span>3</span><span class="token">.</span><span>0
</span>docker pull provectuslabs/kafka-ui:latest

<span>docker tag confluentinc/</span><span class="token">cp</span><span class="token">-</span><span>kafka:7</span><span class="token">.</span><span>3</span><span class="token">.</span><span>0 </span><span class="token">$KAFKA_ECR</span><span>:latest
</span><span>docker tag confluentinc/</span><span class="token">cp</span><span class="token">-</span><span>zookeeper:7</span><span class="token">.</span><span>3</span><span class="token">.</span><span>0 </span><span class="token">$ZOOKEEPER_ECR</span><span>:latest
</span><span>docker tag provectuslabs/kafka-ui:latest </span><span class="token">$KAFKA_UI_ECR</span><span>:latest
</span>
<span>docker push </span><span class="token">$KAFKA_ECR</span><span>:latest
</span><span>docker push </span><span class="token">$ZOOKEEPER_ECR</span><span>:latest
</span><span>docker push </span><span class="token">$KAFKA_UI_ECR</span><span>:latest</span></code></div></div></div></div></pre>

### Step 4: Deploy EKS Cluster

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Return to terraform directory</span><span>
</span>cd C:\workspaces\interview\twelve-factor\ecommerce-microservices\terraform\environments\prod

<span></span><span class="token"># Create the EKS cluster</span><span>
</span><span>terraform apply </span><span class="token">-</span><span>target=module</span><span class="token">.</span><span>eks</span></code></div></div></div></div></pre>

### Step 5: Configure kubectl for EKS Access

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Configure kubectl to access your EKS cluster</span><span>
</span><span>aws eks </span><span class="token">update-kubeconfig</span><span></span><span class="token">--</span><span>name ecommerce-eks </span><span class="token">--</span><span>region us-west-2
</span>
<span></span><span class="token"># Verify connection</span><span>
</span>kubectl get nodes</code></div></div></div></div></pre>

### Step 6: Deploy Storage Requirements First

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Apply the complete Terraform configuration for Kubernetes resources</span><span>
</span>terraform apply

<span></span><span class="token"># Wait for resources to be created</span><span>
</span>kubectl get namespace ecommerce
<span>kubectl get pvc </span><span class="token">-</span><span>n ecommerce</span></code></div></div></div></div></pre>

## Phase 4: Application Deployment

### Step 1: Create Kubernetes Deployment Files

Create deployment files for your applications using the ECR image URLs:

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Navigate to a directory for your K8s manifests</span><span>
</span>cd C:\workspaces\interview\twelve-factor\ecommerce-microservices\kubernetes

<span></span><span class="token"># Retrieve ECR URLs again if needed</span><span>
</span>cd C:\workspaces\interview\twelve-factor\ecommerce-microservices\terraform\environments\prod
<span></span><span class="token">$PRODUCT_ECR</span><span> = terraform output </span><span class="token">-</span><span>raw product_service_ecr_repository_url
</span><span></span><span class="token">$KAFKA_ECR</span><span> = terraform output </span><span class="token">-</span><span>raw kafka_ecr_repository_url
</span><span></span><span class="token">$ZOOKEEPER_ECR</span><span> = terraform output </span><span class="token">-</span><span>raw zookeeper_ecr_repository_url
</span><span></span><span class="token">$KAFKA_UI_ECR</span><span> = terraform output </span><span class="token">-</span><span>raw kafka_ui_ecr_repository_url
</span>
<span></span><span class="token"># Go back to Kubernetes directory</span><span>
</span>cd C:\workspaces\interview\twelve-factor\ecommerce-microservices\kubernetes</code></div></div></div></div></pre>

### Step 2: Update Kubernetes Manifests with ECR Image URLs

Edit your deployment files to use ECR URLs:

In

```
postgres-deployment.yaml
```

,

```
zookeeper-deployment.yaml
```

,

```
kafka-deployment.yaml
```

,

```
kafka-ui-deployment.yaml
```

, and

```
product-service-deployment.yaml
```

, update the image references with your ECR URLs.

### Step 3: Deploy Services in Order

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Apply Kubernetes manifests in order</span><span>
</span><span>kubectl apply </span><span class="token">-</span><span>f postgres-deployment</span><span class="token">.</span><span>yaml
</span><span>kubectl apply </span><span class="token">-</span><span>f zookeeper-deployment</span><span class="token">.</span><span>yaml
</span>
<span></span><span class="token"># Wait for Zookeeper to be ready</span><span>
</span><span>kubectl rollout status deployment/zookeeper </span><span class="token">-</span><span>n ecommerce
</span>
<span>kubectl apply </span><span class="token">-</span><span>f kafka-deployment</span><span class="token">.</span><span>yaml
</span><span>kubectl rollout status deployment/kafka </span><span class="token">-</span><span>n ecommerce
</span>
<span>kubectl apply </span><span class="token">-</span><span>f kafka-ui-deployment</span><span class="token">.</span><span>yaml
</span><span>kubectl apply </span><span class="token">-</span><span>f product-service-deployment</span><span class="token">.</span><span>yaml</span></code></div></div></div></div></pre>

### Step 4: Set Up AWS Load Balancer Controller for Ingress

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Add Helm repo for AWS Load Balancer Controller</span><span>
</span><span>helm repo add eks https:</span><span class="token">/</span><span class="token">/</span><span>aws</span><span class="token">.</span><span>github</span><span class="token">.</span><span>io/eks-charts
</span>helm repo update

<span></span><span class="token"># Install the AWS Load Balancer Controller</span><span>
</span>helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
<span></span><span class="token">-</span><span>n kube-system \
</span><span></span><span class="token">--</span><span class="token">set</span><span> clusterName=ecommerce-eks \
</span><span></span><span class="token">--</span><span class="token">set</span><span> serviceAccount</span><span class="token">.</span><span>create=true \
</span><span></span><span class="token">--</span><span class="token">set</span><span> serviceAccount</span><span class="token">.</span><span>name=aws-load-balancer-controller
</span>
<span></span><span class="token"># Deploy ingress</span><span>
</span><span>kubectl apply </span><span class="token">-</span><span>f ingress</span><span class="token">.</span><span>yaml
</span>
<span></span><span class="token"># Wait for the ALB to be provisioned</span><span>
</span><span>kubectl get ingress </span><span class="token">-</span><span>n ecommerce </span><span class="token">--</span><span>watch</span></code></div></div></div></div></pre>

## Phase 5: Verification and Monitoring

### Step 1: Verify All Components

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Check pod status</span><span>
</span><span>kubectl get pods </span><span class="token">-</span><span>n ecommerce
</span>
<span></span><span class="token"># Check services</span><span>
</span><span>kubectl get svc </span><span class="token">-</span><span>n ecommerce
</span>
<span></span><span class="token"># Check ingress</span><span>
</span><span>kubectl get ingress </span><span class="token">-</span><span>n ecommerce</span></code></div></div></div></div></pre>

### Step 2: Set Up CloudWatch for Monitoring

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Deploy AWS CloudWatch agent to EKS</span><span>
</span><span>kubectl apply </span><span class="token">-</span><span>f https:</span><span class="token">/</span><span class="token">/</span><span>raw</span><span class="token">.</span><span>githubusercontent</span><span class="token">.</span><span>com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart</span><span class="token">.</span><span>yaml</span></code></div></div></div></div></pre>

### Step 3: Set Up Prometheus/Grafana (Optional)

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Add Prometheus Helm repo</span><span>
</span><span>helm repo add prometheus-community https:</span><span class="token">/</span><span class="token">/</span><span>prometheus-community</span><span class="token">.</span><span>github</span><span class="token">.</span><span>io/helm-charts
</span>helm repo update

<span></span><span class="token"># Install Prometheus and Grafana</span><span>
</span>helm install prometheus prometheus-community/kube-prometheus-stack \
<span></span><span class="token">--</span><span>namespace monitoring \
</span><span></span><span class="token">--</span><span>create-namespace</span></code></div></div></div></div></pre>

## Phase 6: Post-Deployment Security Auditing

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Run kube-bench for security auditing</span><span>
</span><span>kubectl apply </span><span class="token">-</span><span>f https:</span><span class="token">/</span><span class="token">/</span><span>raw</span><span class="token">.</span><span>githubusercontent</span><span class="token">.</span><span>com/aquasecurity/kube-bench/main/job-eks</span><span class="token">.</span><span>yaml
</span>
<span></span><span class="token"># Check results</span><span>
</span><span>kubectl logs </span><span class="token">-</span><span>l app=kube-bench </span><span class="token">-</span><span>n default</span></code></div></div></div></div></pre>

## Phase 7: Ongoing Maintenance

### Configuration Updates

When making configuration changes:

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Make changes to Terraform files</span><span>
</span>terraform validate
terraform plan
terraform apply</code></div></div></div></div></pre>

### Managing Kubernetes Resources

For Kubernetes-specific updates:

<pre><div><div class="relative box-border flex flex-row items-center justify-between rounded-t border border-gray-500/50 px-2 py-0.5"><div class="absolute inset-0 bg-gray-500 opacity-20"></div><div class="font-sans text-sm text-ide-text-color">powershell</div><div><button data-tooltip="Copied!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Copy</button><button data-tooltip="Inserted!" class="relative rounded px-2 py-1 text-xs whitespace-nowrap text-ide-text-color font-sans hover:bg-gray-500/10 cursor-pointer disabled:cursor-not-allowed after:absolute after:-bottom-1 after:left-2/4 after:-translate-x-1/2 after:translate-y-full after:rounded after:bg-black after:px-1 after:py-0.5 after:text-xs after:text-white after:opacity-0 transition-opacity after:duration-200 after:content-[attr(data-tooltip)]">Insert</button></div></div><div class="language-powershell relative overflow-hidden border-x border-b border-gray-500/50" aria-label="highlighted-code-language-powershell"><div class="w-full overflow-x-auto"><div><code><span class="token"># Apply configuration changes</span><span>
</span><span>kubectl apply </span><span class="token">-</span><span>f updated-deployment</span><span class="token">.</span><span>yaml
</span>
<span></span><span class="token"># Monitor rollout</span><span>
</span><span>kubectl rollout status deployment/product-service </span><span class="token">-</span><span>n ecommerce</span></code></div></div></div></div></pre>

This step-by-step guide follows enterprise best practices for deploying to AWS, including:

* Remote state management
* Incremental deployment
* Security configuration
* Monitoring setup
* Post-deployment auditing

These skills directly demonstrate the expertise required for a Senior DevOps/Cloud Engineer position at Cyber-Infomax Solutions, showing both AWS infrastructure management and Kubernetes orchestration capabilities.
