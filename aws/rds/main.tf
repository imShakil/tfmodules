resource "aws_db_subnet_group" "rds_subg" {
  name       = "${var.prefix}-subnet_group"
  subnet_ids = var.private_subnets

  tags = {
    Name = "${var.prefix}-db-subnet-group"
  }
}

resource "aws_db_instance" "rds" {
  allocated_storage   = var.storage_size
  db_name             = var.rds_name
  engine              = var.engine
  engine_version      = var.engine_version
  instance_class      = var.instance_class
  username            = var.rds_admin
  password            = var.rds_admin_password
  skip_final_snapshot = var.skip_final_snapshot

  identifier             = "${var.prefix}-rds"
  db_subnet_group_name   = aws_db_subnet_group.rds_subg.name
  vpc_security_group_ids = var.security_group_ids

  tags = {
    Name = "${var.prefix}-rds-mysqldb"
  }

}
