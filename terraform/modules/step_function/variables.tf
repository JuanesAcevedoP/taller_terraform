variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "gx_job_name" {
  type = string
}

variable "bronze_to_silver_job_name" {
  type = string
}

variable "silver_to_gold_job_name" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {}
}