resource "aws_elasticache_subnet_group" "redis" {
  name = "${var.name}-redis"

  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.name}-redis-subnet-group"
  }
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.name}-redis"
  description          = "Redis session store for ${var.name}"

  engine = "redis"

  node_type          = var.node_type
  port               = local.redis_port
  num_cache_clusters = 2

  automatic_failover_enabled = true

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [var.redis_security_group_id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  tags = {
    Name = "${var.name}-redis"
  }
}