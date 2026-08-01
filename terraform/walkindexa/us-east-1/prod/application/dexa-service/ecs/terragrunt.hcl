# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# This is the configuration for Terragrunt, a thin wrapper for Terraform and OpenTofu that helps keep your code DRY and
# maintainable: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

# Include the root `terragrunt.hcl` configuration. The root configuration contains settings that are common across all
# components and environments, such as how to configure remote state.
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Include the envcommon configuration for the component. The envcommon configuration contains settings that are common
# for the component across all environments.
include "envcommon" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/application/dexa-service/ecs.hcl"
  expose = true
}

# Configure the version of the module to use in this environment. This allows you to promote new versions one
# environment at a time (e.g., qa -> stage -> prod).
terraform {
  source = "${include.envcommon.locals.base_source_url}"
}

# ---------------------------------------------------------------------------------------------------------------------
# Override parameters for this environment
# ---------------------------------------------------------------------------------------------------------------------

dependency "vpc" {
  config_path = "../../../vpc"
}

dependency "application_load_balancer" {
  config_path = "../../shared/application-load-balancer"
}

dependency "ecs_cluster" {
  config_path = "../../shared/core-ecs-cluster"
}

dependency "core_rds_database" {
  config_path = "../../shared/core-rds-database"
}

dependency "core_security_groups" {
  config_path = "../../../core-security-groups"
} /*

dependency "core_opensearch_domain" {
  config_path = "../../shared/core-opensearch-domain"
}*/

dependency "ecr" {
  config_path = "../ecr"
}

dependency "ecs_secrets" {
  config_path = "../ecs-secrets"
}

dependency "mysql_service_user" {
  config_path = "../mysql-service-user"
}

locals {
  database_schema = "walkindexa" # TODO: Create this database in terraform

  # Combined JSON secret holding all the externally-managed app credentials (Stripe, Telesign,
  # AWS SMS) as separate keys, referenced below via the ":jsonKey::" ECS valueFrom suffix instead
  # of one Secrets Manager secret per credential. DATABASE_PASSWORD deliberately stays out of this
  # — it's auto-generated/rotated by the rds-cluster module (see mysql_service_user dependency),
  # not something to hand-maintain in a combined blob.
  # TODO: replace with the real ARN once this secret is created (see rollout notes).
  app_secrets_arn = "arn:aws:secretsmanager:us-east-1:019476883234:secret:dexa-service-app-secrets-cjJDfh"
}

# inputs get merged with the common inputs from the root and the envcommon terragrunt.hcl
inputs = {
  desired_count  = 1
  cpu_units      = 512
  memory_units   = 1024
  container_port = 9080

  scheduled_scaling_config = {
    pause_service_period = {
      start_at_utc = "cron(0 4 * * ? *)"
      end_at_utc   = "cron(0 11 * * ? *)"
    }
    min_task_count = 1
    max_task_count = 1
  }

  default_image = "${dependency.ecr.outputs.ecr.url}:latest"

  vpc_id         = dependency.vpc.outputs.vpc_id
  subnet_ids     = dependency.vpc.outputs.private_subnets
  ecs_cluster_id = dependency.ecs_cluster.outputs.ecs_cluster_id

  environment_variables = {
    RUNNING_PROFILE                  = "prod"
    DATABASE_URL                     = "jdbc:mysql://${dependency.core_rds_database.outputs.rw_endpoint}/${local.database_schema}?serverTimezone=UTC&zeroDateTimeBehavior=convertToNull&allowPublicKeyRetrieval=true"
    DATABASE_USERNAME                = dependency.mysql_service_user.outputs.mysql_username
    DATABASE_SCHEMA                  = local.database_schema
    RUNNING_PROFILE                  = include.envcommon.locals.env
    BASE_URL                         = "https://www.${include.envcommon.locals.domain}"
    API_BASE_URL                     = "https://users.api.${include.envcommon.locals.domain}" # https://users.api.walkindexa.com
    DATA_LOAD_JOB_ENABLED            = false
    PASSWORD_RESET_JOB_ENABLED       = false
    EMAIL_JOB_ENABLED                = false
    SMS_JOB_ENABLED                  = false
    COMMON_QUEUE_JOB_ENABLED         = false
    APPOINTMENT_REMINDER_JOB_ENABLED = false
    SERVER_PORT                      = "9080"
    SERVER_SECURITY_PORT             = "9081"
    AWS_SMS_REGION                   = "us-east-1"
  }

  secrets = merge({
    DATABASE_PASSWORD     = dependency.mysql_service_user.outputs.mysql_user_password_secret_arn
    STRIPE_SECRET_KEY     = "${local.app_secrets_arn}:STRIPE_SECRET_KEY::"
    STRIPE_WEBHOOK_SECRET = "${local.app_secrets_arn}:STRIPE_WEBHOOK_SECRET::"
    TELESIGN_CUSTOMER_ID  = "${local.app_secrets_arn}:TELESIGN_CUSTOMER_ID::"
    TELESIGN_API_KEY      = "${local.app_secrets_arn}:TELESIGN_API_KEY::"
    AWS_ACCESS_KEY_ID     = "${local.app_secrets_arn}:AWS_ACCESS_KEY_ID::"
    AWS_SECRET_ACCESS_KEY = "${local.app_secrets_arn}:AWS_SECRET_ACCESS_KEY::"
  }, dependency.ecs_secrets.outputs.secret_arns)

  # DNS is in Cloudflare — after apply, add a CNAME in Cloudflare:
  #   users.api.walkindexa.com → <application-load-balancer DNS name>
  domain_configuration = {
    domain_name      = "users.api.${include.envcommon.locals.domain}"
    create_dns_entry = false
    hosted_zone_id   = null
  }
  lb_listener_arn  = dependency.application_load_balancer.outputs.default_listener_arn
  lb_matching_path = ["/api/v1/*", "/swagger/users/*", "/walkindexa-services/users/*", "/api/v1/auth/*"]

  health_check = {
    path     = "/actuator/health"
    timeout  = "30"
    interval = "60"
    port     = "9081"
  }

  extra_iam_policies = {}
  whitelist_security_group_ids = [
    dependency.application_load_balancer.outputs.default_security_group_id,
    dependency.core_security_groups.outputs.bastion_security_group
  ]
  additional_security_group_ids = [
    dependency.core_rds_database.outputs.default_application_access_security_group_id
  ]

  additional_port_mappings = [
    {
      containerPort = 9081
      hostPort      = 9081
    }
  ]
}
