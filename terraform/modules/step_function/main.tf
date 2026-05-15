# Rol para Step Functions
resource "aws_iam_role" "stepfunctions_role" {
  name = "${var.project}-${var.env}-stepfunctions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  # SIN TAGS (para evitar error de permisos)
}

# Política para ejecutar Glue jobs
resource "aws_iam_policy" "stepfunctions_glue_policy" {
  name = "${var.project}-${var.env}-stepfunctions-glue-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:GetJob"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "stepfunctions_glue_attach" {
  role       = aws_iam_role.stepfunctions_role.name
  policy_arn = aws_iam_policy.stepfunctions_glue_policy.arn
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Step Function
resource "aws_sfn_state_machine" "defunciones_pipeline" {
  name     = "pipeline_datalake_defunciones"
  role_arn = aws_iam_role.stepfunctions_role.arn

  definition = jsonencode({
    Comment = "Pipeline con Great Expectations → Bronze → Silver → Gold"
    StartAt = "DataQualityValidation"
    States = {
      DataQualityValidation = {
        Type = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = var.gx_job_name
        }
        Next = "bronzeToSilverDefuncionesJob"
        Catch = [
          {
            ErrorEquals = ["States.TaskFailed"]
            Next = "DataQualityFailed"
            ResultPath = "$.error"
          }
        ]
        Comment = "Ejecuta las 10 validaciones GX sobre el dataset en Bronze"
      }
      DataQualityFailed = {
        Type = "Fail"
        Error = "DataQualityError"
        Cause = "Great Expectations: una o más validaciones fallaron"
      }
      bronzeToSilverDefuncionesJob = {
        Type = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = var.bronze_to_silver_job_name
        }
        Next = "silverToGoldDefuncionesJob"
        Catch = [
          {
            ErrorEquals = ["States.TaskFailed"]
            Next = "PipelineFailed"
            ResultPath = "$.error"
          }
        ]
      }
      silverToGoldDefuncionesJob = {
        Type = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = var.silver_to_gold_job_name
        }
        Next = "PipelineSuccess"
        Catch = [
          {
            ErrorEquals = ["States.TaskFailed"]
            Next = "PipelineFailed"
            ResultPath = "$.error"
          }
        ]
      }
      PipelineSuccess = {
        Type = "Succeed"
        Comment = "Todas las etapas completadas exitosamente"
      }
      PipelineFailed = {
        Type = "Fail"
        Error = "PipelineError"
        Cause = "Falló una etapa de transformación"
      }
    }
  })

  # SIN TAGS (para evitar error de permisos)
}