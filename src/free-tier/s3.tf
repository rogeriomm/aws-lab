module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "${var.name}-bucket-1"
  acl    = "private"

  versioning = {
    enabled = false
  }
}
