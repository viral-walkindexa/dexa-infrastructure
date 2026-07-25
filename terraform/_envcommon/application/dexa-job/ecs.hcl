# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION
# This is the common component configuration for mysql. The common variables for each environment to
# deploy mysql are defined here. This configuration will be merged into the environment configuration
# via an include block.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  account = local.account_vars.locals.account_name
  # Extract out common variables for reuse
  env = local.environment_vars.locals.environment
  domain = local.environment_vars.locals.domain

  region = local.region_vars.locals.aws_region

  # Expose the base source URL so different versions of the module can be deployed in different environments. This will
  # be used to construct the source URL in the child terragrunt configurations.
  base_source_url = "${get_repo_root()}/../dexa-terraform-modules/modules/ecs"
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  environment    = "${local.env}"
  region         = local.region
  name_prefix    = "walkindexa-dexa-job"

  default_listener_rule_priority = 14
}
