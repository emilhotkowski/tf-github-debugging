locals {
  resource_prefix = "${var.project_name}-${var.env_name}"

  common-tags = map(
    "Project", var.project_name,
    "Environment", var.env_name
  )
}

