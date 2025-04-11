# AWS AppConfig Application
resource "aws_appconfig_application" "feature_flags_app" {
  name        = var.config_file_name
  description = "Feature flags application created from ${var.config_file_name}"
  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# AWS AppConfig Environment
resource "aws_appconfig_environment" "feature_flags_env" {
  name           = var.environment
  description    = "Environment for ${var.config_file_name} based on branch ${var.environment}"
  application_id = aws_appconfig_application.feature_flags_app.id
  
  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# AWS AppConfig Configuration Profile
resource "aws_appconfig_configuration_profile" "feature_flags_profile" {
  name           = var.config_file_name
  description    = "Configuration profile for ${var.config_file_name}"
  application_id = aws_appconfig_application.feature_flags_app.id
  location_uri   = "hosted"
  type           = "AWS.AppConfig.FeatureFlags"
  
  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# AWS AppConfig Deployment Strategy
resource "aws_appconfig_deployment_strategy" "quick_deployment" {
  name                           = "quick-deployment-strategy"
  description                    = "Quick deployment strategy with no bake time or growth interval"
  deployment_duration_in_minutes = 0
  growth_factor                  = 100
  final_bake_time_in_minutes     = 0
  growth_type                    = "LINEAR"
  replicate_to                   = "NONE"
}

# Hosted Configuration Version
resource "aws_appconfig_hosted_configuration_version" "feature_flags_version" {
  application_id           = aws_appconfig_application.feature_flags_app.id
  configuration_profile_id = aws_appconfig_configuration_profile.feature_flags_profile.configuration_profile_id
  description              = "Feature flags configuration version ${var.config_version}"
  content_type             = "application/json"
  
  content = file("/var/jenkins_home/workspace/appconfig-feature-flags-wrk1/config/tst_feature_flags.json")
  
}
