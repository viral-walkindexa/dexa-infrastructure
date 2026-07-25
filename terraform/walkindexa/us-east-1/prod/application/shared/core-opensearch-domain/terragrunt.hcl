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
  path = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/application/shared/core-opensearch-domain.hcl"
  # We want to reference the variables from the included config in this configuration, so we expose it.
  expose = true
}

# Configure the version of the module to use in this environment. This allows you to promote new versions one
# environment at a time (e.g., qa -> stage -> prod).
terraform {
  source = "${include.envcommon.locals.base_source_url}"
}

dependency "vpc" {
  config_path = "../../../vpc"
}

dependency "core_security_groups" {
  config_path = "../../../core-security-groups"
}

# ---------------------------------------------------------------------------------------------------------------------
# Override parameters for this environment
# ---------------------------------------------------------------------------------------------------------------------

# inputs get merged with the common inputs from the root and the envcommon terragrunt.hcl
inputs = {
  vpc_id         = dependency.vpc.outputs.vpc_id
  vpc_subnet_ids = [dependency.vpc.outputs.private_subnets[0]]
  whitelist_security_group_ids = [dependency.core_security_groups.outputs.bastion_security_group]
  cluster_configuration = {
    instance_type            = "t3.small.search"
    dedicated_master_enabled = false
    dedicated_master_count   = 0
    instance_count           = 1
  }

  ebs_storage_volume_size_gb = 10
  engine_version             = "OpenSearch_2.19"
  master_password            = null
  encrypt_at_rest            = false
}
