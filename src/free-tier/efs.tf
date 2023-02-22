# https://aws.amazon.com/blogs/aws/new-for-amazon-efs-iam-authorization-and-access-points/
# https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonelasticfilesystem.html
module "efs" {
  source = "terraform-aws-modules/efs/aws"

  name       = "${var.name}-efs"
  encrypted  = false

  performance_mode = null
  throughput_mode = null
  provisioned_throughput_in_mibps = null

  attach_policy = false
}
