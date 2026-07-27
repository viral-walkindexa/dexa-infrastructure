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
  path = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/application/dexa-job/ecs.hcl"
  # We want to reference the variables from the included config in this configuration, so we expose it.
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
}

dependency "mysql_service_user" {
  config_path = "../../dexa-service/mysql-service-user"
}

/*dependency "core_opensearch_domain" {
  config_path = "../../shared/core-opensearch-domain"
}*/

dependency "ecr" {
  config_path = "../ecr"
}

dependency "ecs_secrets" {
  config_path = "../ecs-secrets"
}

locals {
  database_schema = "walkindexa" # TODO: Create this database in terraform
}

# inputs get merged with the common inputs from the root and the envcommon terragrunt.hcl
inputs = {
  desired_count  = 1
  cpu_units      = 512
  memory_units   = 1024
  container_port = 9080

  default_image = "${dependency.ecr.outputs.ecr.url}:latest"

  vpc_id         = dependency.vpc.outputs.vpc_id
  subnet_ids     = dependency.vpc.outputs.private_subnets
  ecs_cluster_id = dependency.ecs_cluster.outputs.ecs_cluster_id

  environment_variables = {
    RUNNING_PROFILE                             = "${include.envcommon.locals.env}-job"
    DATABASE_URL                                = "jdbc:mysql://${dependency.core_rds_database.outputs.rw_endpoint}/${local.database_schema}?serverTimezone=UTC&zeroDateTimeBehavior=convertToNull&allowPublicKeyRetrieval=true"
    DATABASE_USERNAME                           = "dexa-service"
    DATABASE_SCHEMA                             = local.database_schema
    RUNNING_PROFILE                             = include.envcommon.locals.env
    BASE_URL                                    = "https://www.${include.envcommon.locals.domain}"
    API_BASE_URL                                = "https://users.api.${include.envcommon.locals.domain}" # https://users.api.walkindexa.com
    LIQUIBASE_ENABLED                           = false
    RUNNING_PROFILE                             = "${include.envcommon.locals.env}-job"
    SMTP_HOST                                   = "email-smtp.us-east-1.amazonaws.com"
    SMTP_PORT                                   = "587"
    DATA_LOAD_JOB_ENABLED                       = true
    DATA_LOAD_JOB_SCHEDULE_IN_MILLIS            = 300000 # 5 mins in milliseconds
    PASSWORD_RESET_JOB_FREQ_IN_MILLIS           = 86400000 # 24 hours in milliseconds
    PASSWORD_RESET_JOB_ENABLED                  = true
    EMAIL_JOB_FREQ_IN_MILLIS                    = 5000 # 5 seconds in milliseconds
    EMAIL_JOB_ENABLED                           = true
    COMMON_QUEUE_JOB_ENABLED                    = true
    COMMON_QUEUE_JOB_SCHEDULE_IN_MILLIS         = 5000 # 5 seconds in milliseconds
    APPOINTMENT_REMINDER_JOB_ENABLED            = true
    APPOINTMENT_REMINDER_JOB_SCHEDULE_IN_MILLIS = 3600000 # 1 hour in milliseconds
    CART_ABANDONMENT_JOB_CRON                   = "0 0 10 * * ?" # Every day at 10:00 UTC
    SERVER_PORT                                 = "9080"
    SERVER_SECURITY_PORT                        = "9081"
  }

  secrets = merge({
    DATABASE_PASSWORD     = dependency.mysql_service_user.outputs.mysql_user_password_secret_arn
    STRIPE_SECRET_KEY     = "arn:aws:secretsmanager:us-east-1:019476883234:secret:STRIPE_SECRET_KEY-BODtBh"
    STRIPE_WEBHOOK_SECRET = "arn:aws:secretsmanager:us-east-1:019476883234:secret:STRIPE_WEBHOOK_SECRET-bkk87p"
    TELESIGN_CUSTOMER_ID  = "arn:aws:secretsmanager:us-east-1:019476883234:secret:TELESIGN_CUSTOMER_ID-2ID1oW"
    TELESIGN_API_KEY      = "arn:aws:secretsmanager:us-east-1:019476883234:secret:TELESIGN_API_KEY-EWaIhL"
  }, dependency.ecs_secrets.outputs.secret_arns)

  # DNS is in Cloudflare — dexa-job runs internally; no public DNS entry needed.
  domain_configuration = {
    domain_name      = "users-job.api.${include.envcommon.locals.domain}"
    create_dns_entry = false
    hosted_zone_id   = null
  }
  lb_listener_arn = dependency.application_load_balancer.outputs.default_listener_arn
  lb_matching_path = ["/noneshouldmatchthisone/*"]

  health_check = {
    path     = "/actuator/health"
    timeout  = "30"
    interval = "60"
    port     = "9081"
  }

  extra_iam_policies = {}
  whitelist_security_group_ids = [dependency.application_load_balancer.outputs.default_security_group_id, dependency.core_security_groups.outputs.bastion_security_group]
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
