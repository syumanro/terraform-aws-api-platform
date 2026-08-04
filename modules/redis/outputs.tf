# -----------------------------------------------------------------------------
# Redis Outputs
# -----------------------------------------------------------------------------

output "primary_endpoint_address" {
  description = "Address of the primary endpoint for the ElastiCache replication group."
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Address of the reader endpoint for the ElastiCache replication group."
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
}

output "port" {
  description = "Port used by the ElastiCache replication group."
  value       = aws_elasticache_replication_group.redis.port
}

output "replication_group_id" {
  description = "ID of the ElastiCache replication group."
  value       = aws_elasticache_replication_group.redis.id
}

output "replication_group_arn" {
  description = "ARN of the ElastiCache replication group."
  value       = aws_elasticache_replication_group.redis.arn
}
