resource "random_pet" "this" {
  length = 2
}

# https://github.com/terraform-aws-modules/terraform-aws-dynamodb-table/blob/master/examples/basic/main.tf
module "dynamodb_table" {
  source   = "terraform-aws-modules/dynamodb-table/aws"

  create_table = true

  name        = "my-table-${random_pet.this.id}"
  hash_key    = "id"
  range_key   = "title"
  table_class = "STANDARD"

  attributes = [
    {
      name = "id"
      type = "N"
    },
    {
      name = "title"
      type = "S"
    },
    {
      name = "age"
      type = "N"
    }
  ]

  global_secondary_indexes = [
    {
      name               = "TitleIndex"
      hash_key           = "title"
      range_key          = "age"
      projection_type    = "INCLUDE"
      non_key_attributes = ["id"]
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = "staging"
  }
}
