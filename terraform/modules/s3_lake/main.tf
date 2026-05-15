# ============================================
# BUCKETS S3 (crear si no existen)
# ============================================
module "bronze_bucket" {
  source = "../../modules/s3_lake"

  project    = var.project
  bucket_name = "bronze"
  env        = var.env
  account_id = data.aws_caller_identity.current.account_id
  tags       = var.tags
}

module "silver_bucket" {
  source = "../../modules/s3_lake"

  project    = var.project
  bucket_name = "silver"
  env        = var.env
  account_id = data.aws_caller_identity.current.account_id
  tags       = var.tags
}

module "gold_bucket" {
  source = "../../modules/s3_lake"

  project    = var.project
  bucket_name = "gold"
  env        = var.env
  account_id = data.aws_caller_identity.current.account_id
  tags       = var.tags
}

# ============================================
# GLUE JOBS
# ============================================
module "glue_jobs" {
  source = "../../modules/glue"

  project = var.project
  env     = var.env

  glue_role_arn = "arn:aws:iam::941508878188:role/datalake-dev-glue-role"

  raw_bucket     = module.bronze_bucket.bucket_name
  staging_bucket = module.silver_bucket.bucket_name
  gold_bucket    = module.gold_bucket.bucket_name
  temp_bucket    = module.bronze_bucket.bucket_name

  gx_script_location               = "s3://${module.bronze_bucket.bucket_name}/scripts/validate_defunciones_gx.py"
  bronze_to_silver_script_location = "s3://${module.bronze_bucket.bucket_name}/scripts/bronze_to_silver_defunciones.py"
  silver_to_gold_script_location   = "s3://${module.bronze_bucket.bucket_name}/scripts/silver_to_gold_defunciones.py"

  tags = var.tags
}

# ============================================
# STEP FUNCTION
# ============================================
module "step_function" {
  source = "../../modules/step_function"

  project = var.project
  env     = var.env

  gx_job_name               = module.glue_jobs.gx_job_name
  bronze_to_silver_job_name = module.glue_jobs.bronze_to_silver_job_name
  silver_to_gold_job_name   = module.glue_jobs.silver_to_gold_job_name

  tags = var.tags
}