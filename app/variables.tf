
# Combination of env_name and project_name should be unique.
# It is used to separate deployments.
variable "env_name" {
    type = string
}
variable "project_name" {
    type = string
}

variable "app_zip_location" {
    type = string
    default = "../../app/build.zip"
}