output "iam_policies" {
  value = {
    "assets-bucket-access"  = aws_iam_policy.assets_bucket_access.arn
  }
}