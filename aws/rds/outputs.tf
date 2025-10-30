output "rds_info" {
  value = {
    id             = aws_db_instance.rds.id
    hostname       = aws_db_instance.rds.address
    db_name        = aws_db_instance.rds.db_name
    username       = aws_db_instance.rds.username
    endpoint       = aws_db_instance.rds.endpoint
    engine         = aws_db_instance.rds.engine
    instance_class = aws_db_instance.rds.instance_class
    status         = aws_db_instance.rds.status
  }
}
