# Combination of env_name and project_name should be unique.
# It is used to separate deployments.
variable "env_name" {
    type = string
}
variable "project_name" {
    type = string
}

variable "lambdas_s3_state_bucket" {
    type = string
}

variable "github_debugging_lambdas_s3_state" {
    type = string
}