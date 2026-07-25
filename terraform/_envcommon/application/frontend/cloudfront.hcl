# ---------------------------------------------------------------------------------------------------------------------
# COMMON TERRAGRUNT CONFIGURATION
# This is the common component configuration for webserver-cluster. The common variables for each environment to
# deploy webserver-cluster are defined here. This configuration will be merged into the environment configuration
# via an include block.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  account = local.account_vars.locals.account_name
  # Extract out common variables for reuse
  env    = local.environment_vars.locals.environment
  region = local.region_vars.locals.aws_region
  domain = local.environment_vars.locals.domain

  # Expose the base source URL so different versions of the module can be deployed in different environments.
  base_source_url = "${get_repo_root()}/../dexa-terraform-modules/modules/cloudfront-distribution"
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module. This defines the parameters that are common across all
# environments.
# ---------------------------------------------------------------------------------------------------------------------
inputs = {
  base_name_prefix = local.account
  environment      = local.env

  base_domain = local.domain
  # The apex domain is still an alias on this distribution (and stays in the
  # CORS allowlist / ACM SANs) but is 301-redirected to www below. Every
  # clinic site is served from its own subdomain (atlanta.walkindexa.com,
  # chicago.walkindexa.com, ...) from the same distribution — the Angular app
  # resolves the clinic from the subdomain at runtime, so no per-clinic
  # infrastructure is needed.
  domain = local.domain
  alias_domains = ["www.${local.domain}", "*.${local.domain}"]

  use_legacy_oai = true

  # Users often type the bare domain instead of www — send them there instead
  # of serving the franchise site redundantly on two hosts.
  enable_apex_redirect  = true
  apex_redirect_target  = "www.${local.domain}"
}
