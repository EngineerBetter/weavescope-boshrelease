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
  acl           = "private"
  force_destroy = true

  versioning {
    enabled = true
  }
}
