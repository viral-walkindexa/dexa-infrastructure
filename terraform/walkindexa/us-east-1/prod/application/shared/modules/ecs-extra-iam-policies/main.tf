data "aws_iam_policy_document" "assets_bucket_access" {
  statement {
    sid = "AllowAllBucketOperationsInAssetsBucket"

    actions = [
      "s3:*Object"
    ]
    resources = [
      "arn:aws:s3:::${var.assets_bucket_name}",
      "arn:aws:s3:::${var.assets_bucket_name}/*"
    ]
  }
}

resource "aws_iam_policy" "assets_bucket_access" {
  name        = "AllowAllS3OperationsForAssetsBucket"
  description = "Allows all S3 operations for the assets bucket."
  policy      = data.aws_iam_policy_document.assets_bucket_access.json
}
