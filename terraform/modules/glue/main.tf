# Job 1: Great Expectations - Validación de calidad
resource "aws_glue_job" "gx_validation" {
  name     = "validate_defunciones_gx"
  role_arn = var.glue_role_arn

  command {
    script_location = var.gx_script_location
    python_version  = "3"
  }

  default_arguments = {
    "--input_path"     = "s3://${var.raw_bucket}/defunciones/"
    "--output_path"    = "s3://${var.staging_bucket}/defunciones/validations/"
    "--TempDir"        = "s3://${var.temp_bucket}/temp/"
    "--extra-py-files" = "s3://${var.temp_bucket}/dependencies/great_expectations.zip"
    "--job-language"   = "python"
  }

  worker_type       = var.worker_type
  number_of_workers = var.number_of_workers
  glue_version      = var.glue_version
  timeout           = var.timeout

  tags = var.tags
}

# Job 2: Bronze → Silver
resource "aws_glue_job" "bronze_to_silver" {
  name     = "bronze_to_silver_defunciones"
  role_arn = var.glue_role_arn

  command {
    script_location = var.bronze_to_silver_script_location
    python_version  = "3"
  }

  default_arguments = {
    "--input_path"    = "s3://${var.raw_bucket}/defunciones/"
    "--output_path"   = "s3://${var.staging_bucket}/defunciones/"
    "--TempDir"       = "s3://${var.temp_bucket}/temp/"
    "--job-language"  = "python"
  }

  worker_type       = var.worker_type
  number_of_workers = var.number_of_workers
  glue_version      = var.glue_version
  timeout           = var.timeout

  tags = var.tags
}

# Job 3: Silver → Gold
resource "aws_glue_job" "silver_to_gold" {
  name     = "silver_to_gold_defunciones"
  role_arn = var.glue_role_arn

  command {
    script_location = var.silver_to_gold_script_location
    python_version  = "3"
  }

  default_arguments = {
    "--input_path"    = "s3://${var.staging_bucket}/defunciones/"
    "--output_path"   = "s3://${var.gold_bucket}/defunciones/"
    "--TempDir"       = "s3://${var.temp_bucket}/temp/"
    "--job-language"  = "python"
  }

  worker_type       = var.worker_type
  number_of_workers = var.number_of_workers
  glue_version      = var.glue_version
  timeout           = var.timeout

  tags = var.tags
}