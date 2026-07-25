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
    path   = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/application/frontend/s3-bucket-policy.hcl"
    # We want to reference the variables from the included config in this configuration, so we expose it.
    expose = true
  }

  dependency "s3" {
    config_path = "../s3"
  }

  dependency "cloudfront" {
    config_path = "../cloudfront"
  }

  terraform {
    source = "./" # This points to the current directory with the `main.tf` file
  }

  # ---------------------------------------------------------------------------------------------------------------------
  # Override parameters for this environment
  # ---------------------------------------------------------------------------------------------------------------------

  # inputs get merged with the common inputs from the root and the envcommon terragrunt.hcl
  inputs = {
    frontend_cloudfront_oai_iam_arn = dependency.cloudfront.outputs.oai_iam_arn
    s3_bucket_id = dependency.s3.outputs.bucket_id
    s3_bucket_name = dependency.s3.outputs.bucket_name
  }
