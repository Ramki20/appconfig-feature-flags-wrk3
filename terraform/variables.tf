variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (derived from Git branch name)"
  type        = string
}

variable "config_file_name" {
  description = "Configuration file name without extension"
  type        = string
}

variable "config_content" {
  description = "JSON content of the configuration file (compact format without whitespace)"
  type        = string
}

variable "config_version" {
  description = "Version of the configuration"
  type        = string
}

variable "feature_flags_file_path" {
  description = "Path to the feature flags JSON file"
  type        = string
  default     = "tst_feature_flags.json"
}
