# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Terragrunt "live" infrastructure config for WalkInDexa's AWS account (`019476883234`, `us-east-1`, single environment: `prod`). There is no CI/CD pipeline for this repo — changes are applied manually via the Terragrunt CLI from a local machine with AWS credentials for the `default` profile.

This repo contains **no reusable Terraform module code** — every stack's `terragrunt.hcl` points at a module living in the sibling repo `../dexa-terraform-modules` (see below). The two repos are meant to be checked out side by side.

## Commands

Run from inside a specific stack directory (the one containing a `terragrunt.hcl`):

```bash
terragrunt plan
terragrunt apply
```

To operate on a whole subtree at once (e.g. everything under `application/`):

```bash
terragrunt run-all plan
terragrunt run-all apply
```

There's no linter/test suite — validate with `terragrunt plan` before applying.

## Config hierarchy

Terragrunt merges config top-down via `include` blocks and `find_in_parent_folders()`. From outermost to innermost:

| File | Scope | Key locals |
|---|---|---|
| `terraform/walkindexa/account.hcl` | account | `account_name`, `aws_account_id` |
| `terraform/walkindexa/us-east-1/region.hcl` | region | `aws_region` |
| `terraform/walkindexa/us-east-1/prod/env.hcl` | environment | `environment`, `domain` (`walkindexa.com`) |
| `terraform/walkindexa/service.hcl` | account-wide "service" tag | `service_name` |
| `terraform/root.hcl` | everything | generates the AWS provider block + S3 remote state backend, merges the locals above as `inputs` |
| `terraform/_envcommon/**/*.hcl` | one per component | module source URL + inputs common across environments |
| `terraform/walkindexa/us-east-1/prod/**/terragrunt.hcl` | one per stack instance | environment-specific input overrides |

The remote state bucket is `terragrunt-walkindexa-tf-state-<account_id>-<region>`, one state file per stack at `<path_relative_to_include>/tf.tfstate`.

**Note the root file is `root.hcl`, not `terragrunt.hcl`** — `find_in_parent_folders("root.hcl")` is how every stack locates it. Don't rename it.

## Module sourcing — the important gotcha

Every `_envcommon/*.hcl` file sets a `base_source_url` like:

```hcl
base_source_url = "${get_repo_root()}/../dexa-terraform-modules/modules/vpc"
```

This is a **local relative path**, not a versioned git ref or registry source. That means:
- `dexa-terraform-modules` must be checked out as a sibling directory to this repo (`../dexa-terraform-modules` relative to this repo's root).
- There is no version pinning between the two repos. Editing a module in `dexa-terraform-modules` takes effect on the *next* `terragrunt apply` here — immediately, with no explicit promotion/bump step. When changing a module, re-run `terragrunt plan` in every stack that consumes it to see the blast radius before applying.

## Stacks

```
terraform/walkindexa/us-east-1/prod/
├── vpc/                          # VPC, subnets, NAT
├── core-security-groups/         # shared security groups
├── bastion-hosts/                # SSH bastion
└── application/
    ├── shared/                   # core-rds-database, core-ecs-cluster, core-opensearch-domain,
    │                              #   application-load-balancer, acm-certificates, dns-zone, ses
    ├── dexa-service/              # ecr, ecs, ecs-secrets, mysql-service-user
    ├── dexa-job/                  # ecr, ecs, ecs-secrets (scheduled ECS tasks)
    └── frontend/                  # s3, s3-bucket-policy, cloudfront
```

ECS service names follow the pattern `walkindexa-<component>-fargate-service-prod` in cluster `walkindexa-core-prod` (e.g. `walkindexa-dexa-service-fargate-service-prod`, `walkindexa-dexa-job-fargate-service-prod`). CloudWatch log group: `walkindexa-dexa-service-fargate-logs-prod`.

## ECS secrets — read only at task startup

The `ecs-secrets` stacks wire AWS Secrets Manager ARNs (e.g. `TELESIGN_CUSTOMER_ID`, `STRIPE_SECRET_KEY`) into the ECS task definition as environment variables. **ECS resolves these ARNs once, at task launch — not live.** Updating a secret's value in Secrets Manager does *not* affect already-running tasks; you must force a new deployment for it to take effect:

```bash
aws ecs update-service --cluster walkindexa-core-prod \
  --service walkindexa-dexa-service-fargate-service-prod \
  --force-new-deployment --region us-east-1
```

Before checking secret *values* while debugging, note the timestamps: `aws secretsmanager describe-secret --secret-id <NAME>` gives `LastChangedDate` without exposing the value; compare that against `aws ecs describe-services ... --query 'services[0].deployments'` `createdAt` to tell whether a running task actually picked up a given secret update.

## Before deploying to a new AWS account

Update `aws_account_id` in `terraform/walkindexa/account.hcl`. See the root `CLAUDE.md` (one level up, in the `walkindexa/` workspace root) for the full pre-production checklist (OAuth keys, Stripe keys, SMTP, Jasypt password, Firebase, JWT keys).
