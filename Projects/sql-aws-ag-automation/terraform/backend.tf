terraform {
    backend "s3" {
        bucket          = "sql-ag-terraform-state"
        key             = "prod/terraform.tfstate"
        region          = "us-east-1"
        dynamo_table    = "terraform-lock"
        encrypt         = true

    }
}