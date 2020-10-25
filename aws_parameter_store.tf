resource "aws_ssm_parameter" "app_debug" {
  name        = "/${local.app_name}/env/app_debug"
  value       = "false"
  type        = "String"
  description = "debug mode false"
}

resource "aws_ssm_parameter" "app_env" {
  name        = "/${local.app_name}/env/app_env"
  value       = "production"
  type        = "String"
  description = "environment is production"
}

resource "aws_ssm_parameter" "app_name" {
  name        = "/${local.app_name}/env/app_name"
  value       = local.title
  type        = "String"
  description = "application name"
}

resource "aws_ssm_parameter" "app_url" {
  name        = "/${local.app_name}/env/app_url"
  value       = local.path
  type        = "String"
  description = "application full url"
}

resource "aws_ssm_parameter" "guest_password" {
  name        = "/${local.app_name}/db/guest_password"
  value       = "not_initialized"
  type        = "SecureString"
  description = "guest user password"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "stateful_domains" {
  name        = "/${local.app_name}/sanctum/stateful_domains"
  value       = local.domain
  type        = "String"
  description = "stateful domains for sanctum"
}

resource "aws_ssm_parameter" "session_domain" {
  name        = "/${local.app_name}/sanctum/session_domain"
  value       = ".${local.domain}"
  type        = "String"
  description = "session domain for sanctum"
}

resource "aws_ssm_parameter" "s3_bucket" {
  name        = "/${local.app_name}/s3/bucket"
  value       = aws_s3_bucket.main.bucket
  type        = "String"
  description = "s3 bucket name"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "s3_access_key_id" {
  name        = "/${local.app_name}/s3/id"
  value       = "not_initialized"
  type        = "SecureString"
  description = "s3 access key id"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "s3_secret_key" {
  name        = "/${local.app_name}/s3/secret_key"
  value       = "not_initialized"
  type        = "SecureString"
  description = "s3 secret key"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "s3_default_region" {
  name        = "/${local.app_name}/s3/region"
  value       = "ap-northeast-1"
  type        = "String"
  description = "s3 default region"
}

resource "aws_ssm_parameter" "db_name" {
  name        = "/${local.app_name}/db/name"
  value       = local.app_name
  type        = "String"
  description = "database name"
}

resource "aws_ssm_parameter" "db_host" {
  name        = "/${local.app_name}/db/host"
  value       = aws_db_instance.main.address
  type        = "SecureString"
  description = "database host name"

  # lifecycle {
  #     ignore_changes = [value]
  # }
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/${local.app_name}/db/password"
  value       = "not_initialized"
  type        = "SecureString"
  description = "database password"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "db_user_name" {
  name        = "/${local.app_name}/db/user_name"
  value       = "not_initialized"
  type        = "SecureString"
  description = "database user name"

  lifecycle {
    ignore_changes = [value]
  }
}