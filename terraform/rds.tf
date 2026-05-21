resource "aws_security_group" "fastApi_rds_sg" {
  name        = "postgres-sg"
  description = "Allow PostgreSQL access"
  vpc_id      = aws_vpc.fastApi_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.fastApi_ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "fastApi_rds" {
  allocated_storage      = 20
  db_name                = "fastApi_db"
  engine                 = "postgres"
  engine_version         = "17.10"
  instance_class         = "db.t3.micro"
  username               = "dbadmin"
  password               = "ChangeMe123456!"
  skip_final_snapshot    = true
  publicly_accessible    = false
  storage_encrypted      = true
  db_subnet_group_name   = aws_db_subnet_group.fastApi_rds_snetgroup.name
  vpc_security_group_ids = [aws_security_group.fastApi_rds_sg.id]
  multi_az               = true #create HA "Standby Replica" automatically (NOT for reads, only for disaster recovery)
}

resource "aws_db_subnet_group" "fastApi_rds_snetgroup" {
  name       = "api-dev-rds-subnet-group"
  subnet_ids = [aws_subnet.fastApi_sn_private_1.id, aws_subnet.fastApi_sn_private_2.id]
}
