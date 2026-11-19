# MissionTrack Complete Interview, Rapid-Fire, and Troubleshooting Guide

## How to Study This Guide

This guide is based on the MissionTrack project built hands-on with Azure, Terraform, AKS, Kubernetes, Key Vault, Workload Identity, Trivy, GitHub Actions, Ingress, TLS, HPA, and Azure Monitor.

Use this answer structure in interviews:

1. **What** was the problem or technology?
2. **Why** was it needed?
3. **Where** was it used in MissionTrack?
4. **How** was it implemented and validated?
5. **When** would it be used in production?
6. **Example** of a real failure or troubleshooting step.

Do not memorize every sentence. Practice explaining each answer naturally in 60–120 seconds.

> \\\\\\\*\\\\\\\*Security note:\\\\\\\*\\\\\\\* Do not put real passwords, tokens, private keys, kubeconfig files, or Terraform state in Git.

\---

# 1\. MissionTrack Project Overview

MissionTrack is an Azure DevSecOps and Kubernetes security project that demonstrates:

* Azure infrastructure provisioning with Terraform
* Azure Kubernetes Service application hosting
* Azure Container Registry for container images
* Azure Key Vault for centralized secret management
* AKS Workload Identity and OIDC federation
* Kubernetes RBAC and dedicated service accounts
* Deployments, Services, NGINX Ingress, and TLS
* Resource requests, limits, probes, and HPA
* Azure Monitor, Log Analytics, and Container Insights
* Trivy scanning in GitHub Actions
* Git-based source control and CI security gates

## Architecture

```text
Developer
   |
   v
GitHub Repository
   |
   v
GitHub Actions
   |-- Terraform format and validation
   |-- Trivy IaC and manifest scan
   |-- Build container on hosted runner
   |-- Scan image
   |-- Push immutable image to ACR
   |-- Deploy to AKS
   |-- Verify rollout and smoke test

Internet
   |
   v
Azure Load Balancer
   |
   v
NGINX Ingress Controller
   |
   v
TLS-enabled Ingress
   |
   v
ClusterIP Service
   |
   v
Kubernetes Deployment
   |
   v
Application Pods

Application Pod
   |
   v
Kubernetes Service Account
   |
   v
AKS OIDC Federation
   |
   v
User-Assigned Managed Identity
   |
   v
Azure Key Vault
```

\---

# 2\. Interview Introductions

## 30-Second Version

> I built MissionTrack as an Azure DevSecOps and Kubernetes security project. Terraform manages Azure and Kubernetes resources, AKS runs the workloads, Workload Identity provides passwordless Key Vault access, and Trivy in GitHub Actions blocks insecure configuration. I also implemented NGINX Ingress, TLS, HPA, and Azure Monitor for secure exposure, scaling, and observability.

## Two-Minute Version

> I built MissionTrack to practice end-to-end Azure DevSecOps and AKS platform engineering. I used Terraform to manage an Azure resource group, ACR, Key Vault, a user-assigned managed identity, Key Vault RBAC and firewall rules, and Kubernetes resources including a namespace, service account, deployment, service, ingress, and HPA.
>
> For identity, I enabled OIDC and AKS Workload Identity, created a federated identity credential, and granted the managed identity the Key Vault Secrets User role. I validated the design by retrieving a Key Vault secret from a pod without storing a client secret in Kubernetes.
>
> For security, I created namespace-scoped RBAC and validated permissions with `kubectl auth can-i`. I integrated Trivy with GitHub Actions so High and Critical findings fail the pipeline. Trivy identified an unrestricted Key Vault firewall and default Kubernetes security contexts. I changed the vault to default deny, allowed the required AKS outbound IP, and hardened deployable manifests.
>
> I also deployed NGINX Ingress, created TLS with cert-manager, configured resource requests and limits, readiness and liveness probes, HPA, metrics-server validation, Azure Monitor, Log Analytics, and Container Insights. The project gave me real troubleshooting experience across Terraform, AKS, identity, networking, Git, security scanning, and CI/CD.

\---

# 3\. Resume Bullets

* Built an Azure AKS DevSecOps platform using Terraform, ACR, Azure Key Vault, managed identities, Kubernetes RBAC, NGINX Ingress, TLS, HPA, and Azure Monitor.
* Implemented AKS Workload Identity through OIDC federation, enabling passwordless access from Kubernetes workloads to Azure Key Vault.
* Enforced least privilege with namespace-scoped Roles, RoleBindings, and dedicated service accounts; validated access using `kubectl auth can-i`.
* Integrated Trivy into GitHub Actions to block High and Critical Terraform, Kubernetes, and Dockerfile misconfigurations.
* Remediated a Critical Key Vault exposure by implementing default-deny network ACLs and permitting only required AKS outbound traffic.
* Imported manually created Azure identities and RBAC assignments into Terraform state and achieved a zero-drift plan.
* Implemented Terraform-managed Kubernetes namespaces, service accounts, deployments, services, ingress, resource governance, health probes, and HPA.
* Enabled Azure Monitor, Log Analytics, and Container Insights and validated pod and node resource metrics.
* Implemented TLS on NGINX Ingress with cert-manager and Kubernetes TLS secrets.
* Troubleshot container startup failures caused by non-root and read-only filesystem controls and documented secure compatibility options.

\---

# 4\. Terraform Questions and Answers

## Q1. Why did you use Terraform?

**Answer:** Terraform provides repeatable, version-controlled, reviewable infrastructure. It supports dependency management, previewing changes, state tracking, drift detection, imports, and CI/CD integration.

**MissionTrack example:** The managed identity and Key Vault role assignment were originally created manually. I added matching Terraform resources, imported their Azure IDs, and iterated until `terraform plan` showed no changes.

## Q2. Explain `terraform init`, `validate`, `plan`, and `apply`.

* `init`: initializes providers, modules, and backend.
* `validate`: checks configuration syntax and consistency.
* `plan`: compares configuration, state, and real infrastructure.
* `apply`: performs the reviewed changes.

**Real-life example:** Before changing the Key Vault firewall to default deny, I reviewed a plan showing zero additions, one in-place update, and zero destroys.

## Q3. Why is `terraform plan` important?

**Answer:** It is a change-risk control. It exposes deletion, replacement, and configuration drift before execution. In production, a plan should be reviewed in a pull request and approved before apply.

## Q4. What is Terraform state?

**Answer:** State maps Terraform resource addresses to real resource IDs and stores attributes Terraform needs to calculate changes.

**Why:** Without state, Terraform cannot reliably know which real object belongs to each resource block.

## Q5. Why should state not be committed to Git?

**Answer:** State is environment-specific and can contain sensitive values or infrastructure metadata. It also creates collaboration conflicts.

## Q6. Why use remote state?

**Answer:** Remote state provides shared access, locking, controlled permissions, backups, and CI/CD support.

**MissionTrack example:** Azure Storage was used as the backend instead of relying only on local state.

## Q7. Why commit `.terraform.lock.hcl`?

**Answer:** It records selected provider versions and hashes so developers and CI use consistent dependencies.

## Q8. What should be in `.gitignore`?

```gitignore
.terraform/
\\\\\\\*.tfstate
\\\\\\\*.tfstate.\\\\\\\*
\\\\\\\*.tfvars
\\\\\\\*.tfvars.json
\\\\\\\*.tfplan
crash.log
```

## Q9. What is Terraform import?

**Answer:** Import associates an existing infrastructure object with a Terraform resource address. It does not generate a complete, correct resource block automatically.

## Q10. What is drift?

**Answer:** Drift is a difference between declared Terraform configuration and real infrastructure, often caused by manual portal or CLI changes.

**Detection:** Run `terraform plan`.

## Q11. What would you do if Terraform proposed deleting a Key Vault?

**Answer:** Stop. Review the diff and state. Determine whether the resource address changed, import was incorrect, or a replacement attribute changed. Protect the vault with lifecycle controls if appropriate, back up critical data, and require explicit approval.

## Q12. How would you recover lost state?

**Answer:** Stop applies, restore backend version or backup, or rebuild state using imports. Validate every plan before applying.

## Q13. How would you make Terraform production-ready?

**Answer:** Use modules, independent environment state, secure remote backend, secret management, policy checks, pull-request plans, protected applies, version constraints, tests, and documented recovery procedures.

## Q14. What causes an unclosed configuration block error?

**Answer:** Missing or extra braces, partial file overwrite, or incorrectly nested resource blocks.

**Commands:**

```powershell
Get-Content .\\\\\\\\main.tf -Raw
terraform fmt
terraform validate
```

\---

# 5\. Azure, Identity, and Key Vault Questions

## Q15. What is AKS Workload Identity?

**Answer:** It allows an AKS workload to exchange a projected Kubernetes service-account token for a Microsoft Entra token through OIDC federation, avoiding a stored client secret.

## Q16. Why is OIDC required?

**Answer:** The OIDC issuer lets Microsoft Entra validate Kubernetes service-account tokens and establish trust with the cluster.

## Q17. Explain the Workload Identity flow.

```text
Pod
 -> Service Account
 -> Projected OIDC Token
 -> Federated Identity Credential
 -> Managed Identity
 -> Azure RBAC
 -> Key Vault
```

## Q18. What must match for federation?

* OIDC issuer URL
* Exact subject such as `system:serviceaccount:missiontrack-dev:workload-identity-sa`
* Audience `api://AzureADTokenExchange`
* Service account annotation with managed identity client ID
* Pod label enabling Workload Identity

## Q19. How did you validate Workload Identity?

**Answer:** I deployed a labeled pod using the annotated service account. The pod retrieved the Key Vault secret successfully without a stored Azure client secret.

## Q20. Why is Workload Identity better than a service-principal secret?

**Answer:** It removes long-lived credentials, reduces rotation work, uses short-lived tokens, and scopes access to a workload identity.

## Q21. Authentication versus authorization?

**Answer:** Authentication proves identity. Authorization determines allowed actions.

**MissionTrack example:** Azure recognized the signed-in identity, but Key Vault returned `ForbiddenByRbac` until a data-plane role was assigned.

## Q22. Control plane versus data plane?

**Answer:** Control-plane permissions manage the Key Vault resource. Data-plane permissions control secrets, keys, and certificates inside it.

## Q23. Why use Key Vault?

**Answer:** Key Vault centralizes secrets, access control, auditing, rotation, deletion protection, and integration with managed identity.

## Q24. Are Kubernetes Secrets encrypted?

**Answer:** Base64 encoding is not encryption. Encryption at rest depends on cluster configuration. RBAC and external secret stores remain important.

## Q25. Why use the Key Vault Secrets User role?

**Answer:** It grants read access to secret values without unnecessary administrative rights. This supports least privilege.

## Q26. Why did Trivy flag Key Vault?

**Answer:** The network ACL default action was Allow. I configured default Deny and allowed the required AKS outbound IP.

## Q27. What would you use in production instead of an IP allowlist?

**Answer:** Prefer private endpoints, private DNS, network segmentation, and controlled egress where required.

## Q28. Why use ACR?

**Answer:** ACR provides an Azure-integrated private image registry with RBAC and enterprise networking options.

## Q29. Which AKS identity pulls images from ACR?

**Answer:** Usually the AKS kubelet identity, granted the `AcrPull` role on the registry.

\---

# 6\. Kubernetes Questions and Answers

## Q30. Pod versus Deployment?

**Answer:** A Pod is a runtime unit. A Deployment manages replicas, updates, rollback, and self-healing.

## Q31. Deployment versus StatefulSet?

**Answer:** Deployments suit stateless workloads. StatefulSets provide stable names, ordered operations, and persistent storage identity.

## Q32. What is a ReplicaSet?

**Answer:** It ensures a desired number of identical pods. Deployments manage ReplicaSets during rollout history.

## Q33. What is a Service?

**Answer:** A stable DNS name and virtual IP routing to pods selected by labels.

## Q34. ClusterIP versus NodePort versus LoadBalancer?

* ClusterIP: internal cluster access
* NodePort: exposes a port on every node
* LoadBalancer: provisions or integrates with an external load balancer

## Q35. What happens if a Service selector is wrong?

**Answer:** The service has no endpoints and requests fail.

## Q36. What is Ingress?

**Answer:** It defines HTTP/HTTPS host and path routing. An ingress controller implements it.

## Q37. Why can Ingress return 404?

**Answer:** Host or path does not match, wrong ingress class, or request lacks the expected Host header.

## Q38. Why can Ingress return 502?

**Answer:** No healthy service endpoints, wrong target port, pods not Ready, or application not listening.

## Q39. What is readiness?

**Answer:** It controls whether a pod receives traffic.

## Q40. What is liveness?

**Answer:** It controls whether Kubernetes restarts the container.

## Q41. What is a startup probe?

**Answer:** It protects slow-starting containers from premature liveness failure.

## Q42. Why requests and limits?

**Answer:** Requests guide scheduling and HPA calculations. Limits restrict resource consumption.

## Q43. How does HPA work?

**Answer:** HPA reads metrics and adjusts replicas between a minimum and maximum based on a target.

## Q44. Why did HPA show CPU unknown?

**Answer:** Metrics may not have propagated, CPU requests may be missing, metrics-server may be unavailable, or pods may not be Ready.

## Q45. Role versus ClusterRole?

**Answer:** Role is namespace-scoped. ClusterRole can be cluster-wide or reused through namespace RoleBindings.

## Q46. RoleBinding versus ClusterRoleBinding?

**Answer:** RoleBinding grants permissions in one namespace. ClusterRoleBinding grants cluster-wide access.

## Q47. Why dedicated service accounts?

**Answer:** They isolate workload identity, permissions, and audit history.

## Q48. Why set `automountServiceAccountToken: false`?

**Answer:** It avoids exposing Kubernetes API credentials to workloads that do not need them.

## Q49. What is a securityContext?

**Answer:** Pod/container security settings including UID, non-root enforcement, privilege escalation, Linux capabilities, seccomp, and filesystem permissions.

## Q50. Why drop capabilities?

**Answer:** It reduces kernel-level privileges available to the container.

## Q51. Why use `RuntimeDefault` seccomp?

**Answer:** It filters unnecessary or risky system calls using the runtime's default profile.

## Q52. Why did read-only root filesystem break NGINX?

**Answer:** NGINX attempted to create `/tmp/proxy\\\\\\\_temp` and modify generated configuration. Production options include writable `emptyDir` mounts or a hardened image designed for read-only operation.

## Q53. Why did `runAsNonRoot` block the original image?

**Answer:** The image started as UID 0. Kubernetes correctly refused to run it under a non-root requirement.

## Q54. What is NetworkPolicy?

**Answer:** It controls allowed pod ingress and egress for microsegmentation.

## Q55. Why did MissionTrack NetworkPolicy not work?

**Answer:** AKS reported `networkPolicy: none`; the resource existed but no policy engine enforced it.

\---

# 7\. Docker and Container Questions

## Q56. What is a Docker image?

**Answer:** An immutable layered package containing application code, runtime, libraries, and metadata.

## Q57. Image versus container?

**Answer:** An image is the template. A container is a running instance of the image.

## Q58. What is a Dockerfile?

**Answer:** A declarative instruction file used to build a container image.

## Q59. Why use a small base image?

**Answer:** Smaller images reduce download time, storage, package count, and attack surface.

## Q60. Why is `latest` discouraged?

**Answer:** It is mutable and does not identify exact content. Use semantic version, commit SHA, or digest.

## Q61. Why include `USER` in Dockerfile?

**Answer:** It prevents the application from running as root. Trivy flagged the initial Dockerfile because it lacked an explicit non-root user.

## Q62. What is a multi-stage build?

**Answer:** One stage compiles or packages the application, and a smaller final stage contains only runtime artifacts.

## Q63. What is image layering?

**Answer:** Dockerfile instructions create reusable filesystem layers. Ordering affects cache efficiency and image size.

## Q64. What is `.dockerignore`?

**Answer:** It excludes unnecessary or sensitive files from the build context.

**Example:**

```text
.git
.terraform
\\\\\\\*.tfstate
.env
```

## Q65. Why scan images?

**Answer:** To identify vulnerable OS and application dependencies before deployment.

## Q66. Why couldn't MissionTrack build locally?

**Answer:** Corporate restrictions prevented Docker installation. ACR Tasks was also disabled, so the target design shifted to GitHub-hosted runners.

## Q67. Is Docker required for Kubernetes?

**Answer:** No. Kubernetes uses CRI-compatible runtimes such as containerd. Docker can build images, but AKS nodes use containerd.

## Q68. How would GitHub build without local Docker?

**Answer:** GitHub-hosted Ubuntu runners include Docker tooling. The workflow checks out source, authenticates to ACR, builds, scans, tags, and pushes.

## Q69. What is an SBOM?

**Answer:** A Software Bill of Materials lists components and dependencies in an artifact.

## Q70. Why sign images?

**Answer:** Signing provides artifact integrity and provenance. Admission control can allow only trusted images.

\---

# 8\. DevSecOps and CI/CD Questions

## Q71. What did the MissionTrack GitHub workflow do?

**Answer:** Checkout, Terraform setup, format check, backend-disabled initialization, validation, Trivy installation, and blocking configuration scan.

## Q72. Why did the workflow fail?

**Answer:** Trivy found High-severity findings and the command intentionally returned exit code 1.

## Q73. Is that failure good?

**Answer:** Yes. A security gate should block insecure configuration.

## Q74. How should insecure examples be treated?

**Answer:** Put them in a labeled examples directory and exclude them from the blocking production scan or scan them in a non-blocking educational job.

## Q75. What should the full pipeline contain?

```text
PR
 -> format/lint
 -> tests
 -> secrets/SAST/SCA
 -> Terraform validate and plan
 -> IaC scan
 -> build image
 -> image scan
 -> SBOM/signature
 -> push immutable tag
 -> deploy dev
 -> smoke test
 -> approval
 -> deploy production
 -> verify/rollback
```

## Q76. How should GitHub authenticate to Azure?

**Answer:** Prefer GitHub OIDC federation rather than a long-lived Azure client secret.

## Q77. Why separate CI and CD permissions?

**Answer:** Build jobs should not automatically have production deployment permissions. Separation reduces blast radius.

## Q78. What is a protected environment?

**Answer:** A GitHub environment can require approvals and restrict secrets/identity for production deployment.

## Q79. What is a smoke test?

**Answer:** A quick post-deployment test confirming basic application functionality and reachability.

## Q80. What is rollback?

**Answer:** Restoring a previously known-good release, usually by redeploying an immutable image or undoing a Deployment rollout.

\---

# 9\. Monitoring and Operations Questions

## Q81. metrics-server versus Azure Monitor?

**Answer:** metrics-server supplies current CPU/memory data for HPA and `kubectl top`. Azure Monitor provides centralized historical telemetry, logs, queries, dashboards, and alerts.

## Q82. How did you know Container Insights was enabled?

**Answer:** `ama-logs` pods were running in `kube-system` and AKS was connected to the Log Analytics workspace.

## Q83. What would you monitor?

* Node readiness and utilization
* Pod CPU, memory, restarts, OOM kills
* Deployment availability
* HPA at maximum replicas
* Ingress latency, throughput, and 4xx/5xx
* Key Vault access failures
* Pipeline failure rates
* Certificate expiry

## Q84. What alerts would you create?

* Node NotReady
* CrashLoopBackOff
* High restarts
* Unavailable replicas
* Sustained CPU or memory pressure
* HPA maxed out
* Elevated 5xx
* Certificate near expiry
* Unauthorized RBAC changes

## Q85. How would you troubleshoot high memory?

1. `kubectl top nodes`
2. `kubectl top pods -A --sort-by=memory`
3. Inspect requests/limits
4. Check OOM and eviction events
5. Review application memory profiling
6. Scale workloads/nodes if needed

\---

# 10\. Troubleshooting Playbooks

## Kubernetes: Pod Pending

```powershell
kubectl describe pod <pod> -n <namespace>
kubectl get events -n <namespace> --sort-by=.lastTimestamp
kubectl top nodes
```

**Causes:** insufficient resources, taints, selectors, quotas, storage, image pull.

## Kubernetes: CrashLoopBackOff

```powershell
kubectl logs <pod> -n <namespace>
kubectl logs <pod> -n <namespace> --previous
kubectl describe pod <pod> -n <namespace>
```

**Causes:** application exception, command error, missing secret, filesystem permission, probe failure.

## Kubernetes: ImagePullBackOff

```powershell
kubectl describe pod <pod> -n <namespace>
az acr repository list --name missiontrackacr001 --output table
az aks check-acr --resource-group aks-rg --name myaks --acr missiontrackacr001.azurecr.io
```

**Causes:** wrong tag, image absent, missing AcrPull, registry network restriction.

## Kubernetes: Service unavailable

```powershell
kubectl get svc,endpoints,pods -n <namespace> --show-labels
kubectl describe svc <service> -n <namespace>
```

**Causes:** selector mismatch, wrong targetPort, pods not Ready.

## Kubernetes: Ingress 404

**Causes:** host/path mismatch, wrong ingress class, missing Host header.

## Kubernetes: Ingress 502

**Causes:** no healthy endpoints, wrong target port, application not listening.

## Kubernetes: Certificate not Ready

```powershell
kubectl get certificate,certificaterequest,order,challenge -A
kubectl describe certificate nginx-tls -n missiontrack-tf
kubectl logs -n cert-manager deployment/cert-manager
```

## Kubernetes: HPA unknown

```powershell
kubectl describe hpa nginx-hpa -n missiontrack-tf
kubectl top pods -n missiontrack-tf
kubectl get deployment metrics-server -n kube-system
```

## Workload Identity failure

Check pod label, service account annotation, issuer, exact subject, audience, and client ID.

```powershell
kubectl get sa workload-identity-sa -n missiontrack-dev -o yaml
az identity federated-credential list --resource-group rg-missiontrack-dev --identity-name missiontrack-identity
```

## Key Vault ForbiddenByRbac

Check identity principal ID, data-plane role, scope, RBAC mode, propagation, and network path.

## Terraform resource already exists

Add matching configuration, import resource ID, and plan until safe.

## Terraform wants replacement after import

Do not apply. Compare imported attributes and configuration, correct differences, and re-plan.

## GitHub rejects a large provider binary

Add `.terraform/` to ignore and cleanse Git history. Do not use Git LFS for provider binaries.

## ACR Tasks denied

Use GitHub-hosted or approved enterprise build runner.

## Docker: build cannot find Dockerfile

**Cause:** wrong working directory or file saved as `Dockerfile.txt`.

```powershell
dir
Rename-Item Dockerfile.txt Dockerfile
```

## Docker: permission denied after `USER`

**Cause:** runtime user cannot read files or bind privileged port.

**Fix:** choose suitable UID, fix ownership during build, use nonprivileged port, and validate filesystem paths.

## Docker: container exits immediately

**Cause:** foreground process ended or command failed.

**Checks:** inspect logs, Dockerfile CMD/ENTRYPOINT, environment, ports, and permissions.

## Docker: image too large

**Fix:** use multi-stage build, smaller base, clean package caches, and use `.dockerignore`.

## Docker: vulnerability remains after rebuild

**Cause:** stale base image, vulnerable dependency lock, or cached layer.

**Fix:** update base digest/dependencies, build without stale cache when appropriate, rescan, and verify exact digest.

\---

# 11\. STAR Stories

## STAR 1: Key Vault RBAC

**Situation:** Vault creation succeeded, but writing a secret returned `ForbiddenByRbac`.

**Task:** Understand why authorization failed.

**Action:** Distinguished control-plane from data-plane access, retrieved the caller object ID, assigned the minimum required Key Vault role, waited for propagation, and retested.

**Result:** Secret operations succeeded and the project gained a clear authentication-versus-authorization example.

## STAR 2: NetworkPolicy was not enforced

**Situation:** A default-deny object existed, but frontend still reached backend.

**Task:** Verify the control.

**Action:** Checked selectors, described the policy, repeated traffic testing, and queried AKS networking. `networkPolicy` was `none`.

**Result:** Identified an architectural gap and documented required cluster-level enforcement.

## STAR 3: Hardening broke NGINX

**Situation:** Pods crashed after enabling read-only root filesystem.

**Task:** Restore service safely.

**Action:** Logs showed `/tmp/proxy\\\\\\\_temp` creation failed. Retained non-root image, dropped capabilities, and no privilege escalation. Documented writable `emptyDir` or compatible image as the production solution.

**Result:** Replicas became healthy and most hardening remained.

## STAR 4: Terraform import

**Situation:** Identity and RBAC existed outside Terraform.

**Task:** Adopt them without recreation.

**Action:** Added resources, imported IDs, corrected configuration, and repeated plans.

**Result:** Terraform reported no changes and became the source of truth.

## STAR 5: Trivy security gate

**Situation:** GitHub Actions failed.

**Task:** Determine whether CI was broken.

**Action:** Identified Trivy as the failing step, reviewed findings, hardened production files, added Dockerfile non-root execution, and separated training examples.

**Result:** The pipeline demonstrated that insecure changes were blocked before deployment.

## STAR 6: Git large-file rejection

**Situation:** GitHub rejected the provider executable in history.

**Task:** Publish a clean project.

**Action:** Strengthened ignore rules, created a clean orphan branch, recommitted safe files, and replaced history.

**Result:** Repository pushed successfully without providers or state.

## STAR 7: No local Docker and ACR Tasks blocked

**Situation:** Corporate policy blocked Docker Desktop and Azure rejected ACR Tasks.

**Task:** Preserve a container-delivery design.

**Action:** Chose GitHub-hosted runners for remote build, scanning, and ACR push.

**Result:** The CI/CD design remained viable without installing Docker locally.

\---

# 12\. Rapid-Fire Questions with Answers and Examples

## 1\. What is AKS Workload Identity?

Passwordless federation from a Kubernetes service account to an Azure managed identity.

**Example:** MissionTrack's Key Vault test pod used `workload-identity-sa` to read a secret.

## 2\. Why OIDC?

It allows Entra ID to validate the service-account token issued by AKS.

## 3\. What is the federated subject?

`system:serviceaccount:<namespace>:<service-account>`.

**Example:** `system:serviceaccount:missiontrack-dev:workload-identity-sa`.

## 4\. Which identity pulls from ACR?

Usually the AKS kubelet identity with `AcrPull`.

## 5\. Role versus ClusterRole?

Role is namespace-scoped. ClusterRole can be cluster-scoped or reused across namespaces.

## 6\. Why a dedicated service account?

Least privilege, isolation, and auditability.

## 7\. Deployment versus StatefulSet?

Deployment suits stateless replicas. StatefulSet provides stable identity and storage.

## 8\. Why ClusterIP for backend?

The backend should remain internally reachable rather than publicly exposed.

## 9\. Wrong Service selector result?

No endpoints, so traffic fails.

## 10\. Ingress 404 cause?

Host/path mismatch or wrong ingress class.

## 11\. Ingress 502 cause?

No healthy backend endpoints or wrong port.

## 12\. Readiness failure effect?

Removes pod from service traffic.

## 13\. Liveness failure effect?

Restarts container.

## 14\. What enables HPA metrics?

metrics-server and resource requests.

## 15\. Why CPU requests for HPA?

CPU utilization is measured relative to requested CPU.

## 16\. Terraform backend?

Location and mechanism for Terraform state storage.

## 17\. Why commit lock file?

Provider consistency.

## 18\. Why exclude state?

Sensitive and environment-specific content.

## 19\. Does import produce code?

No. It only associates state with an existing resource.

## 20\. How detect drift?

`terraform plan`.

## 21\. What is Key Vault data-plane RBAC?

Authorization to read/write secrets, keys, or certificates.

## 22\. Why Secrets User instead of Administrator?

Least privilege.

## 23\. Why did NetworkPolicy fail?

Cluster had no enforcement engine enabled.

## 24\. How enforce NetworkPolicy?

Use a supported policy data plane and validate allowed and denied traffic.

## 25\. What does Trivy exit code 1 do?

Fails the pipeline when matching findings exist.

## 26\. How handle insecure examples?

Separate them from blocking production scans.

## 27\. Why non-root Docker USER?

Reduces privilege if the application is compromised.

## 28\. Immutable tag?

A tag or digest identifying one fixed artifact, such as Git SHA.

## 29\. Why image signing?

Integrity and provenance verification.

## 30\. What is an SBOM?

Inventory of software components and dependencies.

## 31\. Secure GitHub-to-Azure authentication?

OIDC federation.

## 32\. Protected environment?

GitHub deployment boundary with approvals and scoped credentials.

## 33\. Dev-to-prod promotion?

Promote the same tested immutable artifact through controlled environments.

## 34\. Rollback method?

Redeploy previous image digest or use Deployment rollout undo.

## 35\. Main alerts?

Node NotReady, unavailable replicas, restarts, OOM, 5xx, HPA max, cert expiry.

## 36\. Pod memory investigation?

`kubectl top`, requests/limits, events, OOMs, profiling.

## 37\. Secure AKS API server?

Private cluster or authorized IP ranges, Entra integration, RBAC, disable local accounts.

## 38\. Why disable local AKS accounts?

Prevent unmanaged static admin credentials.

## 39\. Production Key Vault networking?

Private endpoint, private DNS, restricted egress.

## 40\. Biggest MissionTrack lesson?

Validate outcomes. A created policy or successful command does not prove enforcement.

## 41\. What is CrashLoopBackOff?

Kubernetes repeatedly restarts a failing container with increasing delay.

## 42\. What is ImagePullBackOff?

Kubernetes cannot retrieve the image and backs off retries.

## 43\. What is OOMKilled?

The container exceeded memory availability or its limit and was terminated.

## 44\. What is a DaemonSet?

Runs a pod on every selected node, commonly for agents.

## 45\. What is a ConfigMap?

Non-secret configuration storage.

## 46\. Secret versus ConfigMap?

Secret is intended for sensitive data; ConfigMap is not.

## 47\. What is a PVC?

A workload request for persistent storage.

## 48\. What is an init container?

A container that completes setup before app containers start.

## 49\. What is a sidecar?

A supporting container running beside the application in the same pod.

## 50\. What is a namespace?

Logical scope for resources, policy, quota, and names.

## 51\. What is a taint?

A node property that repels pods without matching tolerations.

## 52\. What is affinity?

Rules influencing pod placement relative to nodes or other pods.

## 53\. What is PDB?

PodDisruptionBudget limits voluntary disruption of available replicas.

## 54\. What is rolling update?

Gradual replacement of old replicas with new ones.

## 55\. What is canary deployment?

Release to a small traffic percentage before wider rollout.

## 56\. What is blue-green deployment?

Maintain old and new environments and switch traffic.

## 57\. What is containerd?

A CRI-compatible container runtime used by Kubernetes nodes.

## 58\. Docker CMD versus ENTRYPOINT?

ENTRYPOINT defines executable; CMD supplies default arguments or command.

## 59\. Why `.dockerignore`?

Smaller, faster, safer build context.

## 60\. What is a registry digest?

Content-addressed immutable image identifier.

\---

# 13\. Production Improvements

* Separate dev/test/prod subscriptions or resource groups
* Reusable Terraform modules
* Independent state per environment
* Private or restricted AKS API
* Entra-integrated AKS and disabled local accounts
* Enforced NetworkPolicy
* Trusted DNS and certificates
* Private Key Vault and ACR endpoints
* Admission policy enforcement
* Defender for Containers
* Image scanning, signing, SBOM, provenance
* GitHub OIDC to Azure
* Protected deployment environments
* Immutable image references
* Backup and disaster-recovery testing
* SLOs, alerts, dashboards, and runbooks
* Budget and retention controls

\---

# 14\. Five-Day Practice Plan

## Day 1: Architecture

* Practice 30-second and two-minute introductions
* Draw architecture from memory
* Explain each component's purpose

## Day 2: Terraform and Azure

* State, backend, import, drift
* Key Vault RBAC and networking
* Workload Identity flow

## Day 3: Kubernetes and Docker

* Pods, Deployments, Services, Ingress
* Probes, resources, HPA
* Dockerfile, image, container, registry
* Practice troubleshooting playbooks

## Day 4: Security and CI/CD

* Trivy findings
* GitHub Actions security gate
* Build, scan, push, deploy design
* Rollback and approvals

## Day 5: Mock Interview

* Answer all 60 rapid-fire questions
* Deliver seven STAR stories
* Practice five outage scenarios
* Keep answers concise and evidence-based

\---

# 15\. Final Closing Statement

> MissionTrack gave me end-to-end experience rather than isolated theory. I provisioned and imported infrastructure with Terraform, implemented Kubernetes RBAC and dedicated identities, configured passwordless AKS-to-Key Vault access, exposed workloads through TLS-enabled Ingress, added autoscaling and monitoring, and integrated Trivy into GitHub Actions. I also resolved real issues involving Key Vault authorization, missing NetworkPolicy enforcement, incompatible container hardening, Terraform imports, Git large-file history, and restricted container builds. The project taught me to validate every security, reliability, and delivery control through testing rather than assuming a successful configuration means the intended outcome was achieved.



