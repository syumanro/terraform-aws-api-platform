# -----------------------------------------------------------------------------
# Aurora DB Subnet Group
# -----------------------------------------------------------------------------

resource "aws_db_subnet_group" "aurora" {
  name       = "${var.project_name}-${var.environment}-aurora-subnet-group"
  subnet_ids = var.private_db_subnet_ids

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-aurora-subnet-group"
    }
  )
}

# -----------------------------------------------------------------------------
# Aurora MySQL Cluster
# -----------------------------------------------------------------------------

resource "aws_rds_cluster" "aurora" {
  cluster_identifier = "${var.project_name}-${var.environment}-aurora"

  engine          = "aurora-mysql"
  database_name   = var.database_name
  master_username = var.master_username
  master_password = var.master_password

  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = [var.aurora_security_group_id]

  storage_encrypted   = true
  deletion_protection = false
  skip_final_snapshot = true

  backup_retention_period = 1
  preferred_backup_window = "18:00-19:00"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-aurora"
    }
  )
}

# -----------------------------------------------------------------------------
# Aurora Writer Instance
# -----------------------------------------------------------------------------

resource "aws_rds_cluster_instance" "writer" {
  identifier = "${var.project_name}-${var.environment}-aurora-writer"

  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version

  db_subnet_group_name = aws_db_subnet_group.aurora.name
  publicly_accessible  = false

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-aurora-writer"
      Role = "writer"
    }
  )
}