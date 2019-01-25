resource "aws_s3_bucket" "ci" {
  bucket        = "weave-scope-ci"
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket" "blobstore" {
  bucket        = "weave-scope-blobstore"
  acl           = "public-read"
  force_destroy = true

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_policy" "blob-public-read" {
  bucket = "${aws_s3_bucket.blobstore.id}"

  policy = <<POLICY
{
  "Statement": [{
    "Action": [ "s3:GetObject" ],
    "Effect": "Allow",
    "Resource": "arn:aws:s3:::weave-scope-blobstore/*",
    "Principal": { "AWS": ["*"] }
  }]
}
POLICY
}

resource "aws_s3_bucket" "releases" {
  bucket        = "weave-scope-releases"
  acl           = "public-read"
  force_destroy = true

  versioning {
    enabled = true
  }
}
