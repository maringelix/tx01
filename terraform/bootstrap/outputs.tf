output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.tf_state.arn
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.tf_locks.arn
}
