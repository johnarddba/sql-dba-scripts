resource "aws_instance" "sqlserver" {
    ami             = "ami-0abcdef123456"
    instance_type   = "t3.large"

    tags = {
        Name = "SQLServer-Terraform"
    }
}
