\# MissionTrack



\## Overview



MissionTrack is a cloud-native DevSecOps project built on Azure and AKS.



\## Technologies



\- Terraform

\- Azure Kubernetes Service (AKS)

\- Azure Container Registry (ACR)

\- Azure Key Vault

\- Managed Identity

\- Workload Identity

\- Trivy

\- GitHub Actions



\## Security Controls



\### Identity



\- AKS Workload Identity

\- OIDC Federation

\- Azure Managed Identity



\### Access Control



\- Kubernetes RBAC

\- Dedicated Service Accounts

\- Least Privilege



\### Secrets Management



\- Azure Key Vault

\- Key Vault RBAC

\- Passwordless Secret Access



\### Infrastructure Security



\- Terraform Infrastructure as Code

\- Terraform Import

\- Drift Detection



\### Security Validation



\- Trivy IaC Scanning

\- Kubernetes Manifest Scanning

\- Key Vault Network Restrictions



\## Key Achievement



AKS workloads retrieve Key Vault secrets using Workload Identity without storing credentials in Kubernetes.



\## Security Observation



AKS cluster is currently configured with:



networkPolicy: none



This means Kubernetes NetworkPolicy resources are not enforced.



Future enhancement:

\- Enable Azure or Calico network policy provider

\- Implement micro-segmentation between workloads



Internet

&#x20;   │

&#x20;   ▼

NGINX Ingress

&#x20;   │

&#x20;   ▼

nginx-service

&#x20;   │

&#x20;   ▼

nginx Deployment

&#x20;   │

&#x20;   ▼

Pods



AKS

&#x20;   │

&#x20;   ▼

Workload Identity

&#x20;   │

&#x20;   ▼

Managed Identity

&#x20;   │

&#x20;   ▼

Azure Key Vault

Terraform manages:



\- Azure Infrastructure

\- Kubernetes Namespace

\- Kubernetes Service Accounts

\- Kubernetes Deployments

\- Kubernetes Services



