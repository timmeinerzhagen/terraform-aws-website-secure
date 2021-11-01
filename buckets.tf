/* Website Bucket */
data "aws_iam_policy_document" "s3_website" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetObject"]
    resources = ["${aws_s3_bucket.website.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.main.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "website_access_from_cloudfront" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.s3_website.json
}

resource "aws_s3_bucket" "website" {
  bucket        = "${lower(var.name)}-website-files"
  acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "block_direct_access" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}
