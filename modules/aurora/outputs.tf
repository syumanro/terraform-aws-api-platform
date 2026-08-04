# -----------------------------------------------------------------------------
# Aurora Outputs
# -----------------------------------------------------------------------------

output "cluster_arn" {
  description = "ARN of the Aurora cluster."
  value       = aws_rds_cluster.aurora.arn
}

output "cluster_endpoint" {
  description = "Writer endpoint of the Aurora cluster."
  value       = aws_rds_cluster.aurora.endpoint
}

output "cluster_reader_endpoint" {
  description = "Reader endpoint of the Aurora cluster."
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "cluster_port" {
  description = "Port used by the Aurora cluster."
  value       = aws_rds_cluster.aurora.port
}