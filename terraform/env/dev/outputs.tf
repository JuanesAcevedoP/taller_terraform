output "bronze_bucket_name" {
  value = module.bronze_bucket.bucket_name
}

output "silver_bucket_name" {
  value = module.silver_bucket.bucket_name
}

output "gold_bucket_name" {
  value = module.gold_bucket.bucket_name
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