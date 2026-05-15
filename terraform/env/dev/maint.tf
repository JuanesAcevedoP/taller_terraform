terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.45.0"
    }
  }
  
  backend "s3" {
    bucket         = "datalake-terraform-941508878188"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

# ============================================
# BUCKETS S3 (usar existentes)
# ============================================
data "aws_s3_bucket" "bronze" {
  bucket = "datalake-bronze-941508878188"
}

data "aws_s3_bucket" "silver" {
  bucket = "datalake-silver-941508878188"
}

data "aws_s3_bucket" "gold" {
  bucket = "datalake-gold-941508878188"
}

# ============================================
# GLUE JOBS
# ============================================
module "glue_jobs" {
  source = "../../modules/glue"

  project = var.project
  env     = var.env

  glue_role_arn = "arn:aws:iam::941508878188:role/datalake-dev-glue-role"

  raw_bucket     = data.aws_s3_bucket.bronze.bucket
  staging_bucket = data.aws_s3_bucket.silver.bucket
  gold_bucket    = data.aws_s3_bucket.gold.bucket
  temp_bucket    = data.aws_s3_bucket.bronze.bucket

  gx_script_location               = "s3://${data.aws_s3_bucket.bronze.bucket}/scripts/validate_defunciones_gx.py"
  bronze_to_silver_script_location = "s3://${data.aws_s3_bucket.bronze.bucket}/scripts/bronze_to_silver_defunciones.py"
  silver_to_gold_script_location   = "s3://${data.aws_s3_bucket.bronze.bucket}/scripts/silver_to_gold_defunciones.py"

  tags = var.tags
}

# ============================================
# STEP FUNCTION - Crear nueva (no existe)
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