resource "aws_db_instance" "postgres" {
  identifier = "${var.name}-postgres"

  db_name = var.db_name
  engine  = "postgres"
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage

  username                    = var.db_username
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [var.postgres_security_group_id]

  publicly_accessible = false
  
  skip_final_snapshot   = true
  delete_automated_backups = true
  deletion_protection   = false

  tags = {
    Name = "${var.name}-postgres"
  }
}

resource "aws_db_subnet_group" "postgres" {
  name = "${var.name}-postgres"

  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.name}-postgres-subnet-group"
  }
}