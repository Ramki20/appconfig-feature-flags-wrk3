output "application_id" {
  description = "AWS AppConfig Application ID"
  value       = aws_appconfig_application.feature_flags_app.id
}

output "environment_id" {
  description = "AWS AppConfig Environment ID"
  value       = aws_appconfig_environment.feature_flags_env.id
}

output "configuration_profile_id" {
  description = "AWS AppConfig Configuration Profile ID"
  value       = aws_appconfig_configuration_profile.feature_flags_profile.id
}

output "deployment_strategy_id" {
  description = "AWS AppConfig Deployment Strategy ID"
  value       = aws_appconfig_deployment_strategy.quick_deployment.id
}
