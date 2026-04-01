resource "aws_security_group" "sql_sg" {
    name = "sqlserver-sg"

    ingress {
        from_port   = 1433
        to_port     = 1433
        protocol    = "tcp"
        codr_blocks = ["0.0.0.0/0"]
    }
}