# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION
# This is the common component configuration for webserver-cluster. The common variables for each environment to
# deploy webserver-cluster are defined here. This configuration will be merged into the environment configuration
# via an include block.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  account_vars     = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  account = local.account_vars.locals.account_name
  # Extract out common variables for reuse
  env     = local.environment_vars.locals.environment
  region  = local.region_vars.locals.aws_region
  domain  = local.environment_vars.locals.domain

  # Expose the base source URL so different versions of the module can be deployed in different environments.
  base_source_url = "${get_repo_root()}/../dexa-terraform-modules/modules/s3-bucket"
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  environment  = local.env
  bucket_name = local.domain

  versioning_configuration = "Enabled"

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rules = []
}
