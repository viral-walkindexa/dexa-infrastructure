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
  path = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/application/dexa-service/ecs-secrets.hcl"
  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}

dependency "core_rds_database" {
  config_path = "../../shared/core-rds-database"
}

terraform {
  source = "../../shared/modules/mysql-service-user"
}

# ---------------------------------------------------------------------------------------------------------------------
# Override parameters for this environment
# ---------------------------------------------------------------------------------------------------------------------

# inputs get merged with the common inputs from the root and the envcommon terragrunt.hcl
inputs = {
  name_prefix     = "dexa-service"
  create_database = false
  database_name   = "walkindexa"

  # When developing with an SSH/SSM tunnel, override the real RDS endpoint with the tunneled host:port.
  # For a local tunnel forwarding remote 3306 to local 53306 use: 127.0.0.1:53306
  mysql_endpoint = "127.0.0.1:53306"

  mysql_root_credentials_secret_arn = dependency.core_rds_database.outputs.db_master_password_secret_arn

  user = {
    username = "dexa-service"
    host     = "%"
  }
}
