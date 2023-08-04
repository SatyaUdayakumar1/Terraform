# subnet group for the rds instance
resource "aws_db_subnet_group" "database_subnet_group" {
  name         = "rds_subnet_group"
  subnet_ids   = [
    var.private_database_subnet_az1_id,
    var.private_database_subnet_az2_id
  ]
  description  = "Subnet group for RDS"

  tags   = {
    Name = "RDS subnet group"
  }
}

# create the rds instance
resource "aws_db_instance" "db_instance" {
  engine                  = "postgres"
  engine_version          = "15.2"
  multi_az                = true
  identifier              = "my-db-instance"
  username                = "postgres"
  password                = "<PASSWORD>"            #Replace this with your password
  instance_class          = "db.m5.large"
  allocated_storage       = 20
  db_subnet_group_name    = aws_db_subnet_group.database_subnet_group.name
  vpc_security_group_ids  = [var.database_securitygroup_id]
  db_name                 = "MyDB"
  skip_final_snapshot     = true
}
