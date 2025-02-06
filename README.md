# DevOps Challenge - Solution Overview

This document details the steps I took to complete the DevOps challenge for the DevOps Engineer position at ChicksGrpup. It covers the technologies used, the implementation process, and the reasoning behind key decisions.  

## Introduction

The challenge involved setting up and configuring infrastructure, automating deployments, and ensuring reliability and scalability. In this document, I will walk through my approach, the tools I used, and any challenges I encountered along the way.

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