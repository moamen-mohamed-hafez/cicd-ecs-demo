# 🚀 CI/CD Pipeline — Node.js → Docker → AWS ECS (Fargate)

> A production-ready CI/CD demo that automatically tests, scans, containerizes, and deploys a Node.js API to AWS ECS Fargate using GitHub Actions, Terraform, SonarCloud, and OIDC — no long-lived AWS credentials required.

---

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Tools & Technologies](#tools--technologies)
- [Project Structure](#project-structure)
- [Setup Instructions](#setup-instructions)
- [How the Pipeline Works](#how-the-pipeline-works)
- [Example Workflow](#example-workflow)
- [Screenshots](#screenshots)
- [Future Improvements](#future-improvements)

---

## Architecture Overview

```
Developer pushes to GitHub
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     GitHub Actions Pipeline                     │
│                                                                 │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────────┐   │
│  │  JOB 1       │   │  JOB 2       │   │  JOB 3           │   │
│  │  Test + Scan │──▶│  Build &     │──▶│  Deploy to ECS   │   │
│  │  (Jest +     │   │  Push to ECR │   │  (Force new      │   │
│  │  SonarCloud) │   │              │   │   deployment)    │   │
│  └──────────────┘   └──────────────┘   └──────────────────┘   │
│                                                  │              │
│                                        (if fail) │              │
│                                                  ▼              │
│                                         ┌──────────────────┐   │
│                                         │  JOB 4           │   │
│                                         │  Auto Rollback   │   │
│                                         └──────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────┐
│                        AWS (us-east-1)                   │
│                                                          │
│  Internet → ALB (public) → ECS Fargate (private subnet)  │
│                              │                           │
│                         ECR Registry                     │
│                         (Docker images)                  │
│                                                          │
│  IAM (OIDC) ──────────────────────── S3 (Terraform state)│
└──────────────────────────────────────────────────────────┘
```

The CI/CD flow has four stages that run in sequence:

1. **Test & Scan** — runs on every push and pull request. Installs dependencies, runs Jest tests with coverage, then sends results to SonarCloud for quality gate analysis.
2. **Build & Push** — runs only on pushes to `main`. Authenticates to AWS via OIDC (no stored secrets), builds a multi-stage Docker image, and pushes it to Amazon ECR tagged with the commit SHA.
3. **Deploy** — triggers a rolling ECS Fargate deployment and waits for the service to stabilize before declaring success.
4. **Rollback** — automatically fires if the deploy job fails, reverting the ECS service to its previous task definition.

---

## Tools & Technologies

| Category | Tool | Purpose |
|---|---|---|
| **Runtime** | Node.js 20 + Express 5 | Application server |
| **Testing** | Jest + Supertest | Unit & integration tests with coverage |
| **Quality** | SonarCloud | Static analysis & quality gate |
| **Containers** | Docker (multi-stage) | Image build & packaging |
| **Registry** | Amazon ECR | Private Docker image registry |
| **Orchestration** | Amazon ECS Fargate | Serverless container runtime |
| **Networking** | VPC, ALB, Security Groups | Public load balancer → private containers |
| **IaC** | Terraform ≥ 1.6 | Infrastructure provisioning |
| **CI/CD** | GitHub Actions | Pipeline automation |
| **Auth** | AWS OIDC | Keyless AWS authentication from GitHub |
| **State** | S3 (encrypted) | Remote Terraform state storage |

---

## Project Structure

```
cicd-ecs-demo/
├── .github/
│   └── workflows/
│       └── ci-cd.yml           # GitHub Actions pipeline (4 jobs)
├── src/
│   ├── app.js                  # Express app — /health and /api routes
│   └── server.js               # HTTP server entry point (port 3000)
├── tests/
│   └── app.test.js             # Jest tests for both API routes
├── terraform/
│   ├── main.tf                 # Root module — wires together sub-modules
│   ├── variables.tf            # Input variables with defaults
│   ├── outputs.tf              # Exports cluster/service/ECR names
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── networking/         # VPC, subnets (public/private), security groups
│       ├── ecr/                # ECR repository with image scanning
│       ├── alb/                # Application Load Balancer + target group
│       ├── iam/                # Task execution role, task role, OIDC role
│       └── ecs/                # ECS cluster, task definition, Fargate service
├── coverage/                   # Generated by Jest (not committed in production)
├── Dockerfile                  # Multi-stage build (builder → runtime)
├── .dockerignore
├── package.json
└── package-lock.json
```

### Key file explanations

- **`ci-cd.yml`** — the heart of the project. Defines all four jobs with correct dependencies (`needs:`), branch guards (`if: github.ref == 'refs/heads/main'`), and failure conditions.
- **`Dockerfile`** — two-stage build: the builder stage installs all deps and runs tests; the runtime stage copies only production deps and the source, runs as a non-root `node` user.
- **`terraform/modules/iam/`** — provisions the OIDC trust relationship so GitHub Actions can assume an AWS role without storing credentials.
- **`src/app.js`** — includes a `/health` route required by the ALB target group health check; without it, ECS tasks would cycle unhealthy.

---

## Setup Instructions

### Prerequisites

- AWS account with permissions to create IAM, ECS, ECR, VPC, ALB resources
- Terraform ≥ 1.6 installed locally
- AWS CLI configured (`aws configure`)
- A GitHub repository (fork or push this project)
- A SonarCloud account (free at sonarcloud.io)

### Step 1 — Create the Terraform state bucket

```bash
aws s3 mb s3://cicd-demo-tfstate-<YOUR_ACCOUNT_ID> --region us-east-1
aws s3api put-bucket-versioning \
  --bucket cicd-demo-tfstate-<YOUR_ACCOUNT_ID> \
  --versioning-configuration Status=Enabled
```

Update `terraform/main.tf` with your bucket name.

### Step 2 — Provision AWS infrastructure

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

After apply, note the outputs — you will need them in the next steps:

```bash
terraform output
# ecr_repository_url, ecs_cluster_name, ecs_service_name, github_actions_role_arn
```

### Step 3 — Configure GitHub Secrets

In your GitHub repository → Settings → Secrets → Actions, add:

| Secret Name | Value |
|---|---|
| `AWS_ROLE_ARN` | Value of `github_actions_role_arn` from Terraform output |
| `SONAR_TOKEN` | Token from SonarCloud → My Account → Security |

### Step 4 — Update pipeline environment variables

In `.github/workflows/ci-cd.yml`, update the `env:` block:

```yaml
env:
  AWS_REGION: us-east-1                    # your region
  ECR_REPO:   cicd-demo-dev               # last segment of ecr_repository_url
  ECS_CLUSTER: cicd-demo-dev-cluster       # ecs_cluster_name output
  ECS_SERVICE: cicd-demo-dev-service       # ecs_service_name output
```

### Step 5 — Configure SonarCloud

1. Log in to [sonarcloud.io](https://sonarcloud.io) and import your GitHub repository.
2. Note your **Organization key** and **Project key**.
3. Create a `sonar-project.properties` file at the repository root:

```properties
sonar.projectKey=your-project-key
sonar.organization=your-org-key
sonar.sources=src
sonar.tests=tests
sonar.javascript.lcov.reportPaths=coverage/lcov.info
```

### Step 6 — Push to main and watch it run

```bash
git add .
git commit -m "feat: initial deployment"
git push origin main
```

Navigate to **GitHub → Actions** to watch the pipeline execute.

---

## How the Pipeline Works

### Job 1: Test and Scan (runs on all branches)

```yaml
on:
  push:    { branches: [main] }
  pull_request: { branches: [main] }
```

- Checks out the full git history (`fetch-depth: 0`) so SonarCloud can calculate blame and history metrics.
- Runs `npm ci` for a reproducible install, then `npm test` which generates an `lcov` coverage report under `coverage/`.
- The SonarCloud action uploads coverage and source to the cloud scanner. If the quality gate fails, this job fails and **blocks all downstream jobs**.

### Job 2: Build and Push (main branch only)

- Uses `aws-actions/configure-aws-credentials@v4` with OIDC — GitHub exchanges a short-lived JWT for temporary AWS credentials. **No AWS keys are stored anywhere.**
- Builds the Docker image using the multi-stage `Dockerfile`. Because the builder stage runs `npm test`, a broken image can never be pushed.
- Tags the image with `${{ github.sha }}` — every commit gets its own immutable tag, preventing accidental overwrites.

### Job 3: Deploy to ECS

- Calls `aws ecs update-service --force-new-deployment` which triggers a rolling replacement of running tasks using the newly pushed image.
- Calls `aws ecs wait services-stable` to block the job until ECS confirms all new tasks are healthy and all old tasks are drained. If this times out, the job fails and triggers the rollback.

### Job 4: Rollback (only fires on failure)

```yaml
if: failure()
```

- Queries the current service's task definition ARN (which at this point is still the previous healthy version because ECS hasn't fully swapped yet).
- Re-applies that task definition, reverting the service to the last known good state.

---

## Example Workflow

### Push to a feature branch (Pull Request)

```
git push origin feature/my-change
→ Opens PR targeting main
→ Pipeline triggers Job 1 only:
    ✅ npm test passes
    ✅ SonarCloud quality gate passes
→ PR is safe to merge (build/deploy do NOT run on PRs)
```

### Merge PR to main

```
git merge feature/my-change → main
→ Pipeline triggers all 4 jobs in sequence:
    ✅ Job 1: Tests pass, SonarCloud quality gate passes
    ✅ Job 2: Image built, tagged abc1234, pushed to ECR
    ✅ Job 3: ECS rolling update starts → waits → service stable
    ✅ Deployment complete — app available at ALB DNS
```

### Failed deployment scenario

```
→ Job 3: ECS tasks fail health checks → wait times out → Job 3 fails
→ Job 4 automatically triggers:
    → Queries previous task definition ARN
    → Re-applies it to the ECS service
    → Previous version is restored
```

---

## Screenshots

> **Instructions:** Take these screenshots after running a successful pipeline and add them to a `/docs/screenshots/` folder in the repository. Then update the paths below.

---

### 1. GitHub Actions — Full Pipeline Success

**What it shows:** All four jobs (Test and scan, Build and push image, Deploy to ECS, and the skipped Rollback) displayed as green checkmarks in the Actions workflow run view.

**How to capture:** Go to GitHub → your repository → Actions tab → click on a completed workflow run → take a screenshot of the job graph.

```
📸 [screenshot: docs/screenshots/pipeline-success.png]
```

---

### 2. Jest Test Results with Coverage

**What it shows:** The terminal output from `npm test`, showing both test suites passing and the coverage table (Statements, Branches, Functions, Lines).

**How to capture:** Click on the "Test and scan" job in GitHub Actions → expand the "Run tests with coverage" step.

```
📸 [screenshot: docs/screenshots/jest-coverage.png]
```

---

### 3. SonarCloud Quality Gate — Passed

**What it shows:** The SonarCloud dashboard for this project showing the Quality Gate as "Passed", along with metrics like 0 bugs, 0 vulnerabilities, and coverage percentage.

**How to capture:** Log in to [sonarcloud.io](https://sonarcloud.io) → select your project → the main Overview page.

```
📸 [screenshot: docs/screenshots/sonarcloud-gate.png]
```

---

### 4. Docker Image Pushed to Amazon ECR

**What it shows:** The ECR repository in the AWS Console listing the pushed image, tagged with a git commit SHA, with image size and push date visible.

**How to capture:** AWS Console → Elastic Container Registry → Repositories → `cicd-demo-dev` → Images tab.

```
📸 [screenshot: docs/screenshots/ecr-image.png]
```

---

### 5. ECS Service — Deployment Successful

**What it shows:** The ECS service in the AWS Console showing the service status as "Active", desired count matching running count (e.g., 2/2), and the recent deployment listed as "PRIMARY" and completed.

**How to capture:** AWS Console → Elastic Container Service → Clusters → `cicd-demo-dev-cluster` → Services → `cicd-demo-dev-service` → Deployments tab.

```
📸 [screenshot: docs/screenshots/ecs-deployment.png]
```

---

### 6. Application Health Check Response

**What it shows:** A browser or `curl` response from the `/health` endpoint through the ALB, returning `{"status":"ok","version":"1.0.0"}`.

**How to capture:** Run `curl http://<alb-dns-name>/health` or open the URL in a browser after a successful deployment. The ALB DNS is in the Terraform output.

```
📸 [screenshot: docs/screenshots/health-check.png]
```

---

### 7. Auto Rollback Triggered (Optional — simulate a failure)

**What it shows:** The GitHub Actions workflow run where Job 3 (Deploy) failed and Job 4 (Rollback) automatically ran, shown with a red × on Deploy and a green ✅ on Rollback.

**How to capture:** Deliberately break a health check (e.g., temporarily change `/health` to return 500) and push to main. Screenshot the resulting workflow run.

```
📸 [screenshot: docs/screenshots/auto-rollback.png]
```

---

## Future Improvements

- **Multi-environment support** — add `staging` and `production` environments with manual approval gates between them, using GitHub Environments and protection rules.
- **Semantic versioning** — replace the raw commit SHA tag with semantic version tags (e.g., `v1.2.3`) using a tool like `release-please` or `semantic-release`.
- **Container vulnerability scanning** — enable ECR image scanning on push and fail the pipeline if critical CVEs are found.
- **Terraform remote state locking** — upgrade to DynamoDB-based state locking for the Terraform S3 backend to safely support multiple concurrent developers.
- **Notifications** — add Slack or email alerts on deploy success/failure using the `slack-github-action` or AWS SNS.
- **ECS Exec** — enable ECS Exec on the task definition to allow secure shell access to running containers for debugging without opening SSH ports.
- **Horizontal scaling** — add an ECS Application Auto Scaling policy to scale the desired count based on ALB request count or CPU utilization.
- **Secrets management** — integrate AWS Secrets Manager or Parameter Store to inject secrets into the ECS task definition at runtime instead of using environment variables in plain Terraform.
