resource "aws_s3_bucket_policy" "this" {
  bucket = var.s3_bucket_id

  policy = jsonencode({
    "Id" : "bucket_policy_site",
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "bucket_policy_site_root",
        "Action" : ["s3:ListBucket"],
        "Effect" : "Allow",
        "Resource" : "arn:aws:s3:::${var.s3_bucket_name}",
        "Principal" : { "AWS" : var.frontend_cloudfront_oai_iam_arn }
      },
      {
        "Sid" : "bucket_policy_site_all",
        "Action" : ["s3:GetObject"],
        "Effect" : "Allow",
        "Resource" : "arn:aws:s3:::${var.s3_bucket_name}/*",
        "Principal" : { "AWS" : var.frontend_cloudfront_oai_iam_arn }
      }
    ]
  })
}