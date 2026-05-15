variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "glue_role_arn" {
  type = string
}

variable "raw_bucket" {
  type = string
}

variable "staging_bucket" {
  type = string
}

variable "gold_bucket" {
  type = string
}

variable "temp_bucket" {
  type = string
}

variable "gx_script_location" {
  type = string
}

variable "bronze_to_silver_script_location" {
  type = string
}

variable "silver_to_gold_script_location" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {}
}

variable "glue_version" {
  type    = string
  default = "5.0"
}

variable "worker_type" {
  type    = string
  default = "G.1X"
}

variable "number_of_workers" {
  type    = number
  default = 2
}

variable "timeout" {
  type    = number
  default = 30
}