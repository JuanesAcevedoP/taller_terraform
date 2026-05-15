output "bronze_bucket_name" {
  value = data.aws_s3_bucket.bronze.bucket
}

output "silver_bucket_name" {
  value = data.aws_s3_bucket.silver.bucket
}

output "gold_bucket_name" {
  value = data.aws_s3_bucket.gold.bucket
}

output "gx_job_name" {
  value = module.glue_jobs.gx_job_name
}

output "bronze_to_silver_job_name" {
  value = module.glue_jobs.bronze_to_silver_job_name
}

output "silver_to_gold_job_name" {
  value = module.glue_jobs.silver_to_gold_job_name
}

output "state_machine_arn" {
  value = module.step_function.state_machine_arn
}

output "state_machine_name" {
  value = module.step_function.state_machine_name
}