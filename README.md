# DevOps Challenge - Solution Overview

This document details the steps I took to complete the DevOps challenge for the DevOps Engineer position at ChicksGrpup. It covers the technologies used, the implementation process, and the reasoning behind key decisions.  

## Introduction

The challenge involved setting up and configuring infrastructure, automating deployments, and ensuring reliability and scalability. In this document, I will walk through my approach, the tools I used, and any challenges I encountered along the way.

## Prerequisites

Terraform (This project was done with version v1.9.6) \
AWS CLI \
Python3 (This project was done with version 3.13.1)\
Docker

## Replication steps

### **1)** Create a `terraform.tfvars`

create the file and specificy the following variables:

- region
- name
- vpc_cidr
- azs
- public_subnets
- private_subnets
- intra_subnets
- db_name
- db_username
- db_password
- kms_key_id


For example:
```
region                   = "us-west-1" 
name                     = "my-cluster" 
vpc_cidr                 = "10.1.0.0/16" 
azs                      = ["us-west-1a", "us-west-1b"] 
public_subnets           = ["10.1.1.0/24", "10.1.2.0/24"] 
private_subnets          = ["10.1.3.0/24", "10.1.4.0/24"] 
intra_subnets            = ["10.1.5.0/24", "10.1.6.0/24"]
db_name                  = YOUR_DB_NAME
db_username              = YOUR_DB_USERNAME
db_password              = YOUR_DB_PASSWORD
kms_key_id               = YOUR_KMS_ID
crowdsec_bouncer_api_key = ""
```

##### These are not the exact values i used for this configuration, these are a mere reference


### **2)** Without Basic Authentication Middleware
If you're not interested in running the services behind an authentication middleware, remove the annotation from the ingress of each application

```
manifests/apps/inventory/ingress.yaml

annotations:
    traefik.ingress.kubernetes.io/router.middlewares: traefik-basic-auth@kubernetescrd <- remove this annotation
```

### **2)** With Basic Authentication Middleware
if you want the basic-auth middleware, create the secret with the credentials you're gonna use to authenticate with the service for the External Secrets Operator to pull and inject into Traefik

example:

```
aws secretsmanager create-secret \                
  --name TRAEFIK_BASIC_AUTH_CREDS \
  --secret-string '{"username": "admin", "password": "Secret123"}' \
  --region us-east-1
```

### **3)** Plan and pply

```
terraform plan 
terraform apply
```

### **4)** Build Python Applications

Build images
```
docker build -t product Product
docker build -t inventory Inventory
docker build -t order Order
```
Tag images
```
docker tag product:latest ${YOUR_ACCOUNT_NUMBER}$.dkr.ecr.${YOUR_REGION}.amazonaws.com/product:latest

docker tag inventory:latest ${YOUR_ACCOUNT_NUMBER}$.dkr.ecr.${YOUR_REGION}.amazonaws.com/inventory:latest

docker tag order:latest ${YOUR_ACCOUNT_NUMBER}$.dkr.ecr.${YOUR_REGION}.amazonaws.com/order:latest
```

Push your images
```
docker push 869681612022.dkr.ecr.us-east-1.amazonaws.com/product:latest 

docker push 869681612022.dkr.ecr.us-east-1.amazonaws.com/inventory:latest  

docker push 869681612022.dkr.ecr.us-east-1.amazonaws.com/order:latest  
```

### 5) Apply manifests

Lastly you will have to create all the application manifests such as: \
- Deployments
- Services
- Ingresses
- ExternalSecrets
- HPA

Run:
```
kubectl apply ./manifests
```

## Extra configuration

If you're interested in also deploying crowdsec, as well as connecting it to Traefik Bouncer then there are a couple more step that you'll have to follow:

### Crowdsec

1- Apply the clusterSecretStore to authenticate for the secret to be pulled

```
kubectl apply -f manifests/external-secrets/clusterSecretStore.yaml
```

2- Create the secret with the variables Crowdsec needs to be installed so then the ESO can pull the secret and inject it into your cluster

```
For your ENROLL_KEY create an account at https://www.crowdsec.net/ it's Free
```

```
aws secretsmanager create-secret \                
  --name CROWDSEC_SECRET \
  --secret-string '{"ENROLL_KEY": "YOUR-ENROLL_KEY", "ENROLL_INSTANCE_NAME": "MY-CLUSTER", "ENROLL_TAGS": "k8s linux test"}' \
  --region us-east-1
```

3- Specificy the host that it's gonna be listening to:

```
terraform/helm/crowdsec/values.yaml

lapi:
  dashboard:
    enabled: false
    ingress:
      host: INSERT-YOUR-HOST
```

### Traefik Bouncer

**1-** after installing `Crowdsec` you'll have to exec into the `crowdsec-lapi-*` pod to enroll the Traefik Bouncer

```
kubectl -n crowdsec exec -it crowdsec-lapi-* -- sh
```
then run
```
/ # cscli bouncers add traefik-bouncer 
```

which will then output an API Key and you can place it in your variable `var.crowdsec_bouncer_api_key`

## Services

For the services, 3 small Python applications were developed that interact internally throught AWS Platform with an Database (RDS instance). These services are inventory product and order. 

They all interact with RDS internally, and they also have the necessary health checks to showcase their health as well as verify the health of the other services. For example, I can go to the product route and go to /product/health path and validate the health of the product services, as well as being able yo go to /product/health/order and validate the health of the order service. This will help us later on to validate the connectivity between services.

## Involved tools

- Terraform
- EKS Kubernetes Cluster
- AWS Load Balancer Controller
- Traefik
- Traefik Basic Authentication (Middleware)
- Traefik-bouncer (Middleware)
- Crowdsec
- EBS Container Storage Interface
- Nikto
- External Secrets Operator
- AWS Secret Manager
- RDS Instance
- KMS
- IAM/IRSA

## Diagram

![Image](https://github.com/user-attachments/assets/b8c40859-65ec-47d1-82d6-87c2352138b1)

## Entry Point

For the entry point I configured **Traefik** as a reverse proxy which was deployed by the **AWS Load Balancer controller** as an ALB  (application load balancer). Using this method will allow us to reroute the traffic to the necessary services, as well as implementing Traefik Middlewares that will come handy later on.

By implementing **Traefik Basic Authentication Middleware** were’re able to hide all of our endpoints and paths behind an username and password screen for increased security during testing.

# Traefik + Crowdsec + Traefik Bouncer + Nikto

This section explains how we were able to mitigate bad actors by using **Crowdsec**, which is a collaborative security tool that by and for the community, and shares a list of known bad actors. by using the Crowdsec agent we’re able to parse the logs HTTP Requests that come through Traefik and detect malicious activity and by integrating the Traefik Bouncer we’re able to block bad actors as Crowdsec identifies them through Traefik’s logs.

# Demo

###### By using **Nikto** we’re able to perform HTTP-Probing, which triggers crowdsec alerts and makes the Traefik Bouncer Middleware block us and tag us as bad actors, from there on every request will return code 403 - Forbiden 

https://github.com/user-attachments/assets/5454f74c-8435-4442-b1db-514d9bdf8adb

# External Secrets Operator + Secret Manager + KMS

Using the **External Secrets Operator** i was able to safely store the  all the necessary secrets for this project in the AWS Secret Manager service, as well as descrypt them and inject them into the Kubernetes cluster for the workloads to use. Everything while also being able to safely store the reference here in the Version control tool.

By creating a ClusterSecretStore i was able to use a IAM IRSA Role to provide the Controller with the necessary permissions to be able to pull the secrets from the AWS Secret Manager service, Decrypt them using the KMS Key used when they were created, and finally create a Kuberntes Secrets that holds the content of said Secret for them to be injected into pods later on.

# RDS + EKS + Microservices

The RDS Instance provisions a PostgresSQL database instance within a **private VPC subnet**, the VPC and security groups ensure that only authorized EKS pods can access RDS. Private subnets restrict exposure, enhancing security. Even tho the objective was to make RDS instance accessible only by using IAM DB Authentication, it was later on dismissed to priority delivery time and instead it's using standar username and password 