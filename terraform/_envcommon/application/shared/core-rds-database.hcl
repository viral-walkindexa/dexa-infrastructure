# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION
# This is the common component configuration for mysql. The common variables for each environment to
# deploy mysql are defined here. This configuration will be merged into the environment configuration
# via an include block.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Extract out common variables for reuse
  env = local.environment_vars.locals.environment

  domain = local.environment_vars.locals.domain

  # Expose the base source URL so different versions of the module can be deployed in different environments. This will
  # be used to construct the source URL in the child terragrunt configurations.
  base_source_url = "${get_repo_root()}/../dexa-terraform-modules/modules/rds-instance"
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  apply_immediately = true
  auto_major_version_upgrade = false
  auto_minor_version_upgrade = true

  base_name_prefix = "walkindexa-default-db"
  default_database_name = "walkindexa"

  enable_http_endpoint = false
  engine_configuration = {
    type = "mysql"
    version = "8.4.6"
  }

  master_username = "walkindexa_admin"
  port_number = 3306
  skip_final_snapshot = false
}
