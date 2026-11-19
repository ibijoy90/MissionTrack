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

> MissionTrack gave me end-to-end experience rather than isolated theory. I provisioned and imported infrastructure with Terraform, implemented Kubernetes RBAC and dedicated identities, configured passwordless AKS-to-Key Vault access, exposed workloads through TLS-enabled Ingress, added autoscaling and monitoring, and integrated Trivy into GitHub Actions. I also resolved real issues involving Key Vault authorization, missing NetworkPolicy enforcement, incompatible container hardening, Terraform imports, Git large-file history, and restricted container builds. The project taught me to validate every security, reliability, and delivery control through testing 
rather than assuming a successful configuration means the intended outcome was achieved.

MissionTrack Master Interview and Troubleshooting Guide
About This Guide
This master guide revisits the complete MissionTrack learning journey in the same order the project was built. It includes the interview questions that came up after each concept, practical answers, real examples from the project, troubleshooting steps, STAR stories, Kubernetes and container questions, rapid-fire questions with answers, and production improvements.
Use this response pattern in interviews:
What is the concept?
Why is it needed?
Where did you use it?
How did you implement it?
How did you validate it?
What failed and how did you troubleshoot it?
What would you change for production?
> Do not claim MissionTrack processed real production or sensitive customer traffic. Describe it accurately as a production-style hands-on Azure DevSecOps and AKS project.
---
1. Complete Project Story
30-Second Answer
> I built MissionTrack as an Azure DevSecOps and Kubernetes security project. Terraform manages Azure and Kubernetes resources, AKS runs the workloads, Workload Identity provides passwordless Key Vault access, and GitHub Actions with Trivy enforces security checks. I also implemented RBAC, dedicated service accounts, NGINX Ingress, TLS, HPA, Azure Monitor, Log Analytics, and Container Insights.
Two-Minute Answer
> I built MissionTrack to practice end-to-end Azure DevSecOps and AKS platform engineering. I used Terraform to provision and manage a resource group, Azure Container Registry, Azure Key Vault, a user-assigned managed identity, Key Vault RBAC, firewall rules, and Kubernetes resources such as namespaces, service accounts, deployments, services, ingress, and HPA.
>
> For identity, I enabled the AKS OIDC issuer and Workload Identity. I created a federated identity credential that trusted a Kubernetes service account and granted the managed identity the Key Vault Secrets User role. I validated the complete flow by retrieving a Key Vault secret from a pod without storing an Azure client secret in Kubernetes.
>
> For Kubernetes security, I implemented namespace-scoped RBAC and tested it with `kubectl auth can-i`. I created dedicated service accounts for frontend, backend, and the Key Vault workload. I tested pod security controls such as non-root execution, dropped capabilities, no privilege escalation, and read-only filesystems. I also discovered that a NetworkPolicy resource was accepted but not enforced because the AKS cluster reported `networkPolicy: none`.
>
> For DevSecOps, I added Trivy to GitHub Actions. The pipeline intentionally failed when High or Critical findings existed. Trivy found an unrestricted Key Vault firewall and insecure Kubernetes defaults. I remediated the Key Vault finding by changing the ACL to default deny and allowing the AKS outbound IP. I also implemented NGINX Ingress, cert-manager TLS, health probes, resource requests and limits, HPA, metrics-server validation, Azure Monitor, Log Analytics, and Container Insights.
Architecture
```text
Developer
   |
   v
GitHub Repository
   |
   v
GitHub Actions
   |-- Terraform format check
   |-- Terraform init without production backend
   |-- Terraform validation
   |-- Trivy configuration scan
   |-- Container build on hosted runner (delivery target)
   |-- Image scan and push to ACR (delivery target)
   |-- AKS deployment and smoke test (delivery target)

Internet Client
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
---
2. Phase-by-Phase Questions, Answers, and Real Examples
Phase 1: Terraform and Azure Container Registry
Q1. Why did you use Terraform?
Answer:
> Terraform made infrastructure repeatable, reviewable, and version controlled. It allowed me to validate syntax, preview changes, manage dependencies, detect drift, import existing resources, and use the same workflow in CI/CD.
MissionTrack example:
> I provisioned the resource group, ACR, Key Vault, managed identity, and role assignment with Terraform. After imports and configuration alignment, `terraform plan` returned no changes.
Q2. Explain the Terraform workflow.
```text
terraform init
 -> terraform fmt
 -> terraform validate
 -> terraform plan
 -> review
 -> terraform apply
 -> verify in Azure
```
Q3. Why use ACR?
Answer:
> ACR provides an organization-controlled Azure container registry with Azure RBAC, networking options, and integration with AKS.
Real example:
> MissionTrack created `missiontrackacr001.azurecr.io` with admin access disabled, supporting identity-based authentication instead of registry admin credentials.
Q4. Why disable ACR admin access?
Answer:
> The admin account uses broadly privileged static credentials. Managed identity and RBAC are safer, more auditable, and easier to scope.
Q5. What issue could occur when AKS pulls from ACR?
Answer:
> `ImagePullBackOff` can occur if the image/tag does not exist, the kubelet identity lacks `AcrPull`, the registry URL is wrong, or the registry network rules block AKS.
Troubleshooting:
```powershell
kubectl describe pod <pod> -n <namespace>
az acr repository list --name missiontrackacr001 --output table
az aks check-acr --resource-group aks-rg --name myaks --acr missiontrackacr001.azurecr.io
```
---
Phase 2: Azure Key Vault and RBAC
Q6. Why use Key Vault?
Answer:
> Key Vault centralizes secrets, keys, and certificates and provides RBAC, auditability, soft delete, rotation support, and managed identity integration.
Q7. Why could you create the vault but not create a secret?
Answer:
> Azure separates control-plane permissions from data-plane permissions. I had permission to create the vault resource but initially lacked a Key Vault secrets role, so the operation returned `ForbiddenByRbac`.
Q8. Authentication versus authorization?
Answer:
> Authentication establishes who the caller is. Authorization determines what the caller can do.
MissionTrack example:
> Azure authenticated my CLI identity successfully, but Key Vault blocked secret creation until I received a data-plane role.
Q9. Why use Key Vault Secrets User for the workload?
Answer:
> It provides secret-read access without granting unnecessary vault administration, key management, or role assignment permissions.
Q10. Why did Trivy report the Key Vault as Critical?
Answer:
> The network ACL default action was Allow. Trivy considered that unrestricted network exposure.
Remediation:
Retrieved the AKS effective outbound IP.
Changed Key Vault ACL default action to Deny.
Added the AKS outbound IP rule.
Reviewed Terraform plan.
Applied the change.
Verified the live network ACL and reran Trivy.
Q11. What would you do differently in production?
Answer:
> Prefer a private endpoint, private DNS, controlled egress, stricter RBAC, purge protection, diagnostics, and secret rotation.
---
Phase 3: Kubernetes RBAC
Q12. What is Kubernetes RBAC?
Answer:
> RBAC authorizes actions using Roles, ClusterRoles, RoleBindings, and ClusterRoleBindings.
Q13. Role versus RoleBinding?
Answer:
> A Role defines permissions in a namespace. A RoleBinding assigns those permissions to a user, group, or service account.
Q14. How did you validate least privilege?
Answer:
> I created a read-only Role and bound it to `readonly-user`. I tested it using impersonation.
```powershell
kubectl auth can-i get pods `
  --as=system:serviceaccount:missiontrack-dev:readonly-user `
  -n missiontrack-dev
```
Validated results:
Get pods: yes
Delete deployments: no
Get secrets: no
Q15. Why use dedicated service accounts?
Answer:
> They isolate identity and permissions by workload. MissionTrack used separate service accounts for frontend, backend, read-only access, and Workload Identity.
Q16. Why avoid the default service account?
Answer:
> Sharing one identity makes least privilege and auditing harder and increases blast radius.
---
Phase 4: NetworkPolicy Validation
Q17. What is a NetworkPolicy?
Answer:
> It restricts pod ingress and egress traffic and supports microsegmentation and lateral-movement reduction.
Q18. Why did the default-deny policy not block traffic?
Answer:
> The resource was successfully created, but AKS reported `networkPolicy: none`, meaning there was no enforcement engine.
Q19. What is the lesson?
Answer:
> A created configuration does not prove the intended control is enforced. I tested connectivity before and after the policy and queried the AKS network profile.
Q20. How would you implement it in production?
Answer:
> Enable a supported network-policy data plane when designing the cluster, implement default-deny safely, allow DNS and required service paths, and validate allowed and denied traffic.
---
Phase 5: Pod Security
Q21. Why are privileged containers dangerous?
Answer:
> A privileged container receives extensive host-level capabilities and can significantly increase container-escape and node-compromise risk.
Q22. Why run as non-root?
Answer:
> It reduces impact if the application is compromised and prevents unnecessary UID 0 access.
Q23. Why did `runAsNonRoot` fail with the original NGINX image?
Answer:
> The image was configured to start as root. Kubernetes correctly blocked it because it violated the declared requirement.
Q24. Why did `readOnlyRootFilesystem` break NGINX?
Answer:
> NGINX attempted to write `/tmp/proxy_temp` and generated configuration. The filesystem was read only.
Q25. How would you solve that securely?
Answer:
> Use a compatible hardened image or mount writable `emptyDir` volumes only at required paths. In the lab, I retained other controls and documented the read-only filesystem compatibility issue.
Q26. Why drop Linux capabilities?
Answer:
> It removes kernel-level privileges the workload does not need. Start with drop ALL and add back only explicitly required capabilities.
Q27. What does `allowPrivilegeEscalation: false` do?
Answer:
> It prevents the container process from gaining more privileges than its parent process.
Q28. Why use `seccompProfile: RuntimeDefault`?
Answer:
> It uses the runtime's default system-call filtering profile to reduce syscall attack surface.
---
Phase 6: Workload Identity and Key Vault Access
Q29. Explain Workload Identity step by step.
```text
1. AKS exposes an OIDC issuer.
2. A Kubernetes service account is annotated with a managed identity client ID.
3. A federated credential trusts the issuer, subject, and audience.
4. A labeled pod receives projected token configuration.
5. The token is exchanged for an Entra access token.
6. The managed identity accesses Key Vault through Azure RBAC.
```
Q30. What happens if the federated subject is wrong?
Answer:
> The token exchange fails because the service-account identity does not match the trusted subject.
Q31. How did you prove the connection worked?
Answer:
> The Key Vault verification pod logged that the secret retrieval succeeded. I also inspected the service account, federated credential, role assignment, and projected token configuration.
Q32. What security concern did the verification pod reveal?
Answer:
> It printed a synthetic secret to logs. That is acceptable only as a controlled lab demonstration. A production application must never log secret values. The secret should be rotated if exposed.
---
Phase 7: Terraform State and Import
Q33. Why remote state?
Answer:
> Collaboration, locking, backup, centralized access control, and CI/CD support.
Q34. Why did blob listing fail even though the storage account existed?
Answer:
> The user had management-plane permission but lacked a Blob Data role for data-plane access.
Q35. What is Terraform import?
Answer:
> It associates an existing object with a Terraform address without recreating it.
Q36. What did you import?
Answer:
> The user-assigned managed identity and Key Vault Secrets User role assignment.
Q37. What proves a successful adoption?
Answer:
> A safe `terraform plan` showing no unintended changes. MissionTrack reached “No changes. Your infrastructure matches the configuration.”
---
Phase 8: Trivy Security Scanning
Q38. What did Trivy scan?
Answer:
> Terraform, Kubernetes YAML, and Dockerfile configuration.
Q39. What findings did it identify?
Key Vault network ACL default allow
Privileged container example
Missing pod and container security contexts
Missing read-only root filesystem
Dockerfile without explicit non-root USER
Q40. Why did GitHub Actions fail?
Answer:
> The Trivy command used `--exit-code 1`, so High and Critical findings intentionally failed the workflow.
Q41. Is the failure a pipeline problem?
Answer:
> No. It demonstrated that the security gate worked.
Q42. Why should insecure examples be separated?
Answer:
> Deliberately insecure training files can make a production gate fail forever. They should be excluded from the blocking scan or placed in a separate non-blocking educational job.
Q43. Should every scanner recommendation be applied automatically?
Answer:
> No. Controls must be evaluated and tested for application compatibility. The NGINX read-only filesystem failure demonstrated this.
---
Phase 9: Deployments, Services, and Ingress
Q44. Why replace standalone pods with Deployments?
Answer:
> Deployments provide replicas, self-healing, rolling updates, rollback, and declarative state.
Q45. What is a ClusterIP Service?
Answer:
> An internal stable DNS and virtual IP that routes to matching pods.
Q46. How did you validate service discovery?
Answer:
> I started a BusyBox test pod and used `wget` against the service DNS name. The NGINX page returned successfully.
Q47. What does Ingress provide?
Answer:
> Host- and path-based HTTP/HTTPS routing from the ingress controller to internal services.
Q48. Why was local hosts-file mapping discussed?
Answer:
> The ingress used a local hostname, so the Windows machine needed name resolution or an explicit Host header. Ping itself was not mandatory; HTTP validation was the meaningful test.
---
Phase 10: TLS and cert-manager
Q49. What is cert-manager?
Answer:
> A Kubernetes controller that automates certificate requests, issuance, renewal, and TLS Secret creation.
Q50. What did MissionTrack use?
Answer:
> A self-signed ClusterIssuer for learning, a Certificate resource, and an Ingress TLS reference to `nginx-tls-secret`.
Q51. What would production use?
Answer:
> A trusted enterprise PKI or ACME issuer, real DNS, renewal monitoring, strong TLS policy, and controlled private-key access.
---
Phase 11: Resource Governance and HPA
Q52. Why requests and limits?
Answer:
> Requests drive scheduling and CPU-based HPA calculations. Limits constrain resource usage.
Q53. How does HPA work?
Answer:
> It compares current metrics with a configured target and adjusts replicas within minimum and maximum limits.
Q54. Why did HPA show unknown CPU at first?
Answer:
> Metrics synchronization can take time, and CPU requests must exist. I verified metrics-server and used `kubectl top pods`.
Q55. What if HPA is at maximum but latency remains high?
Answer:
> Investigate whether the bottleneck is CPU, memory, ingress, database, external dependency, or node capacity. HPA cannot solve every bottleneck.
---
Phase 12: Azure Monitor and Container Insights
Q56. metrics-server versus Azure Monitor?
Answer:
> metrics-server provides current resource metrics for `kubectl top` and HPA. Azure Monitor provides centralized logs, inventory, history, dashboards, and alerts.
Q57. How did you verify monitoring?
Answer:
> `kubectl top pods` and `kubectl top nodes` returned metrics, and `ama-logs` pods were running after Container Insights was enabled.
Q58. What would you alert on?
Node NotReady
CrashLoopBackOff
Unavailable replicas
OOM kills
High restarts
Sustained CPU/memory saturation
HPA at maximum
Ingress 5xx and latency
Certificate expiry
Key Vault access failures
---
Phase 13: Git and GitHub
Q59. Why did GitHub reject the first push?
Answer:
> A 238 MB Terraform provider executable existed in previous Git history. GitHub scans the full branch history, not only the current tree.
Q60. How did you fix it?
Answer:
> I improved `.gitignore`, created a clean orphan branch, recommitted only safe current files, replaced the old branch, and pushed clean history.
Q61. Why should provider binaries not be committed?
Answer:
> `terraform init` downloads them. They are platform-specific, large, and unnecessary in source control.
---
Phase 14: Application Build Without Local Docker
Q62. Why was local Docker not used?
Answer:
> Corporate restrictions prevented Docker Desktop installation.
Q63. Why did `az acr build` fail?
Answer:
> First, the Dockerfile was missing or saved as `Dockerfile.txt`. After that was fixed, the subscription returned `TasksOperationsNotAllowed` for ACR Tasks.
Q64. What is the alternative?
Answer:
> Use a GitHub-hosted runner or another approved remote build runner. Docker runs in CI, not on the laptop.
Q65. Is Docker required on AKS nodes?
Answer:
> No. AKS uses containerd. Docker can be used as an image build tool, but Kubernetes communicates through the Container Runtime Interface.
---
3. Kubernetes Troubleshooting Questions and Answers
Q66. A pod is Pending. What do you do?
```powershell
kubectl describe pod <pod> -n <namespace>
kubectl get events -n <namespace> --sort-by=.lastTimestamp
kubectl top nodes
```
Possible causes: resources, taints, selectors, storage, quota, scheduling constraints.
Q67. A pod is in CrashLoopBackOff. What do you do?
```powershell
kubectl logs <pod> -n <namespace>
kubectl logs <pod> -n <namespace> --previous
kubectl describe pod <pod> -n <namespace>
```
MissionTrack example: NGINX logs revealed `/tmp/proxy_temp` could not be created on a read-only filesystem.
Q68. A pod is ImagePullBackOff. What do you check?
Image name and tag
ACR repository and tag existence
`AcrPull` permission
Registry firewall/private DNS
Pod events
Q69. Service exists but app is unreachable. What do you check?
```powershell
kubectl get svc,endpoints,pods -n <namespace> --show-labels
kubectl describe svc <service> -n <namespace>
```
Likely causes: selector mismatch, wrong target port, pod not Ready, app listening elsewhere.
Q70. Ingress returns 404. Why?
Answer: Host/path mismatch, wrong ingress class, or request missing expected Host header.
Q71. Ingress returns 502. Why?
Answer: No healthy backend endpoints, wrong service port/target port, or backend application failure.
Q72. Certificate is not Ready. What do you inspect?
```powershell
kubectl get certificate,certificaterequest,order,challenge -A
kubectl describe certificate <name> -n <namespace>
kubectl logs -n cert-manager deployment/cert-manager
```
Q73. Workload Identity fails. What do you check?
Pod label
Service account annotation
Exact federated subject
OIDC issuer
Audience
Client ID
Azure role assignment
Key Vault network path
Q74. HPA is not scaling. What do you check?
```powershell
kubectl describe hpa <hpa> -n <namespace>
kubectl top pods -n <namespace>
kubectl get deployment metrics-server -n kube-system
```
Also verify container resource requests and actual CPU load.
Q75. Deployment is 0/2 Available. What do you do?
Get pod statuses.
Describe one failed pod.
Read current and previous logs.
Review events.
Check image, security context, volumes, probes, resources, and service account.
Fix smallest safe issue.
Watch rollout.
---
4. Docker and Container Troubleshooting
Q76. Build says Dockerfile not found.
Cause: wrong directory or `Dockerfile.txt`.
```powershell
dir
Rename-Item Dockerfile.txt Dockerfile
```
Q77. Container permission denied after USER.
Cause: non-root user cannot access copied files, directories, or required port.
Fix: set ownership in the image, use nonprivileged ports, and verify writable paths.
Q78. Container exits immediately.
Cause: foreground process ended or CMD/ENTRYPOINT failed.
Check: container logs, Dockerfile command, environment, config, and file permissions.
Q79. Image is too large.
Fix: multi-stage build, smaller base, package-cache cleanup, `.dockerignore`, fewer unnecessary files.
Q80. Image still has vulnerabilities after rebuild.
Cause: outdated base image, dependency lock, or stale cached layer.
Fix: update dependencies and base digest, rebuild, and scan the exact image digest.
Q81. Why avoid root containers?
Answer: Root inside a container can increase impact if isolation is bypassed or host resources are exposed.
Q82. Why use `.dockerignore`?
Answer: It reduces build context size and prevents accidental inclusion of Git history, state, credentials, and local artifacts.
```text
.git
.terraform
*.tfstate
.env
```
---
5. CI/CD and DevSecOps Questions
Q83. What did the first GitHub Actions pipeline do?
Answer: Checkout, Terraform setup, format check, backend-disabled init, validation, Trivy installation, and blocking configuration scan.
Q84. Why use `terraform init -backend=false` in CI validation?
Answer: It initializes providers without requiring access to the production backend during a basic validation job.
Q85. What should the complete pipeline do?
```text
Pull Request
 -> format and lint
 -> unit tests
 -> SAST/SCA/secret scan
 -> Terraform validate and plan
 -> IaC scan
 -> build image
 -> image vulnerability scan
 -> create SBOM and signature
 -> push immutable image to ACR
 -> deploy to dev
 -> smoke test
 -> approval
 -> deploy to production
 -> verify rollout
 -> rollback if needed
```
Q86. How should GitHub authenticate to Azure?
Answer: Use GitHub OIDC federation, scoped Azure RBAC, and protected environments instead of a long-lived client secret.
Q87. Why use immutable tags?
Answer: A Git SHA or digest identifies one exact artifact and supports auditability and reliable rollback.
Q88. What should block deployment?
Failed tests
Exposed secrets
Unapproved Critical vulnerabilities
Invalid Terraform
Failed policy checks
Unsigned image where signing is required
Deployment health failure
Missing approval
---
6. Real-Life STAR Stories
STAR 1: ForbiddenByRbac
Situation: Key Vault existed, but secret creation failed.
Task: Determine why the vault creator could not write a secret.
Action: Distinguished Azure management access from data-plane access, identified the object ID, assigned a minimum required Key Vault role, waited for propagation, and retested.
Result: Secret creation succeeded.
STAR 2: NetworkPolicy not enforced
Situation: Default-deny existed, but traffic remained allowed.
Task: Validate enforcement.
Action: Inspected policy selectors, tested traffic, and queried AKS networking.
Result: Found `networkPolicy: none` and documented a cluster-design remediation.
STAR 3: Security hardening caused outage
Situation: New NGINX replicas failed after enabling a read-only root filesystem.
Task: Restore availability while preserving security.
Action: Read logs, found `/tmp/proxy_temp` write failure, retained non-root and privilege controls, and documented writable volume or compatible image options.
Result: Deployment became 2/2 and later 3/3 healthy.
STAR 4: Terraform import
Situation: Identity and role assignment were manually created.
Task: Bring them under IaC safely.
Action: Defined resources, imported IDs, corrected configuration, and reviewed plans.
Result: Terraform returned no changes.
STAR 5: Trivy blocked GitHub Actions
Situation: The pipeline failed after a push.
Task: Determine if CI was broken.
Action: Reviewed the failed Trivy step, hardened production manifests, added a non-root Docker USER, and separated insecure examples.
Result: Proved the security gate was functioning as designed.
STAR 6: GitHub large-file rejection
Situation: GitHub rejected the Terraform provider binary from history.
Task: publish clean source.
Action: Added correct ignores, created an orphan branch, committed safe content, and replaced history.
Result: GitHub repository synchronized successfully.
STAR 7: No local image build
Situation: Docker Desktop was blocked and ACR Tasks were not permitted.
Task: preserve CI/CD design.
Action: Selected GitHub-hosted runner builds with remote ACR push.
Result: The delivery design remained feasible without changing corporate laptop policy.
---
7. Rapid-Fire Questions with Answers and Examples
1. What is Workload Identity?
Passwordless federation from a Kubernetes service account to an Azure managed identity.
2. Why OIDC?
It enables Entra to validate AKS-issued service account tokens.
3. Federated subject format?
`system:serviceaccount:<namespace>:<service-account>`.
4. Which identity pulls from ACR?
Usually the kubelet identity with `AcrPull`.
5. Role versus ClusterRole?
Role is namespace-scoped; ClusterRole can be cluster-wide or reusable.
6. Why dedicated service accounts?
Isolation, least privilege, auditability.
7. Deployment versus StatefulSet?
Stateless replicas versus stable identity/storage.
8. Why ClusterIP for backend?
Keep it internal.
9. Wrong Service selector?
No endpoints.
10. Ingress 404?
Host/path mismatch.
11. Ingress 502?
No healthy backend or wrong port.
12. Readiness failure?
Stops traffic to the pod.
13. Liveness failure?
Restarts the container.
14. HPA metrics source?
metrics-server.
15. Why CPU requests for HPA?
Utilization is relative to request.
16. Terraform backend?
State storage mechanism/location.
17. Why lock file?
Provider consistency.
18. Why exclude state?
Sensitive and environment-specific.
19. Does import generate code?
No.
20. Drift detection?
`terraform plan`.
21. Key Vault data plane?
Access to secrets, keys, certificates.
22. Why Secrets User?
Least privilege.
23. Why NetworkPolicy failed?
No enforcement engine.
24. How enable it?
Supported network-policy data plane and traffic validation.
25. Trivy exit code 1?
Fails the job on findings.
26. Insecure examples?
Separate from blocking scan.
27. Docker USER?
Avoid root execution.
28. Immutable tag?
Tag/digest tied to exact content.
29. Image signing?
Integrity and provenance.
30. SBOM?
Software component inventory.
31. GitHub-to-Azure auth?
OIDC federation.
32. Protected environment?
Approvals and scoped deployment access.
33. Promotion?
Move same immutable artifact through environments.
34. Rollback?
Deploy previous digest or rollout undo.
35. Main alerts?
Node, pod, rollout, HPA, ingress, certificate, Key Vault.
36. Investigate memory?
Top, limits, OOM events, application profiling.
37. Secure AKS API?
Private/restricted access, Entra, RBAC, disable local accounts.
38. Why disable local accounts?
Avoid unmanaged static admin credentials.
39. Production Key Vault network?
Private endpoint and private DNS.
40. Biggest lesson?
Validate outcomes, not just configuration creation.
41. CrashLoopBackOff?
Repeated failure and delayed restart.
42. ImagePullBackOff?
Image retrieval failure and retry backoff.
43. OOMKilled?
Container exceeded memory availability/limit.
44. DaemonSet?
One pod per selected node.
45. ConfigMap?
Non-secret configuration.
46. Secret versus ConfigMap?
Sensitive versus non-sensitive intent.
47. PVC?
Persistent storage request.
48. Init container?
Runs setup before app containers.
49. Sidecar?
Supporting container in same pod.
50. Namespace?
Logical scope for resources and policy.
51. Taint?
Repels pods without toleration.
52. Affinity?
Influences placement.
53. PDB?
Limits voluntary disruption.
54. Rolling update?
Gradual replica replacement.
55. Canary?
Small initial traffic release.
56. Blue-green?
Parallel old/new environments with traffic switch.
57. containerd?
CRI container runtime used by Kubernetes.
58. CMD versus ENTRYPOINT?
Executable versus defaults/arguments.
59. `.dockerignore`?
Reduces and secures build context.
60. Image digest?
Immutable content identifier.
---
8. Commands to Memorize
Terraform
```powershell
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
terraform state list
terraform import <address> <resource-id>
```
AKS
```powershell
az aks get-credentials --resource-group aks-rg --name myaks --overwrite-existing
kubectl config current-context
kubectl get nodes
```
Troubleshooting
```powershell
kubectl get deployments,pods,svc,ingress,hpa -n missiontrack-tf
kubectl describe pod <pod> -n <namespace>
kubectl logs <pod> -n <namespace>
kubectl logs <pod> -n <namespace> --previous
kubectl get events -n <namespace> --sort-by=.lastTimestamp
kubectl get endpoints -n <namespace>
kubectl top pods -n <namespace>
kubectl top nodes
```
Rollout
```powershell
kubectl rollout status deployment/<name> -n <namespace>
kubectl rollout history deployment/<name> -n <namespace>
kubectl rollout undo deployment/<name> -n <namespace>
```
RBAC
```powershell
kubectl auth can-i get pods -n missiontrack-dev
kubectl auth can-i get secrets -n missiontrack-dev
kubectl auth can-i --list -n missiontrack-dev
```
Azure Identity
```powershell
az aks show --resource-group aks-rg --name myaks --query oidcIssuerProfile
az identity show --resource-group rg-missiontrack-dev --name missiontrack-identity
az identity federated-credential list --resource-group rg-missiontrack-dev --identity-name missiontrack-identity
az role assignment list --assignee-object-id <principal-id> --output table
az keyvault show --name missiontrackkv001 --query properties.networkAcls
```
Security
```powershell
trivy config . --severity HIGH,CRITICAL
trivy config k8s --severity HIGH,CRITICAL --exit-code 1
```
Git
```powershell
git status
git add .
git commit -m "message"
git push
git log --oneline -5
git remote -v
```
---
9. Production Improvements
Separate dev, test, and prod environments
Terraform modules and independent state
Restricted/private AKS API
Entra-integrated AKS and disabled local accounts
Enforced NetworkPolicy
Trusted DNS and certificates
Private endpoints for Key Vault and ACR
Azure Policy/admission enforcement
Defender for Containers
Image scanning, signing, SBOM, provenance
GitHub OIDC to Azure
Protected environments and approvals
Immutable image tags/digests
Backup and DR testing
SLOs, alerts, dashboards, and runbooks
Cost budgets and retention controls
---
10. Five-Day Study Plan
Day 1: Project Story
Practice 30-second and two-minute answers
Draw architecture from memory
Review all phase summaries
Day 2: Terraform, Azure, and Identity
State, backend, import, drift
Key Vault RBAC/firewall
Workload Identity flow
Day 3: Kubernetes and Containers
Pods, Deployments, Services, Ingress
Probes, resources, HPA
Kubernetes and Docker troubleshooting
Day 4: Security and CI/CD
Trivy remediation
GitHub Actions security gate
Build/scan/push/deploy design
Rollback and approvals
Day 5: Mock Interview
Answer all rapid-fire questions
Deliver all STAR stories
Practice five outage scenarios
Keep normal answers 60–120 seconds
---
Final Interview Closing Statement
> MissionTrack gave me end-to-end experience instead of isolated theory. I provisioned and imported infrastructure with Terraform, implemented Kubernetes RBAC and dedicated identities, configured passwordless AKS-to-Key Vault access, exposed workloads through TLS-enabled Ingress, added autoscaling and monitoring, and integrated Trivy into GitHub Actions. I also resolved real issues involving Key Vault authorization, missing NetworkPolicy enforcement, incompatible container hardening, Terraform import and state, Git large-file history, and restricted container builds. The project taught me to validate every security, reliability, and delivery control through testing rather than assuming a successful configuration means the intended outcome was achieved.



