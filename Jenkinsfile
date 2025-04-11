pipeline {
    agent any
    
    tools {
        terraform 'Terraform' // Use the name configured in Global Tool Configuration
    }
    
    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_DEFAULT_REGION    = 'us-east-1'
        CONFIG_DIR = 'config'
    }
    
    parameters {
        string(name: 'CONFIG_FILE', defaultValue: 'tst_feature_flags.json', description: 'Name of the feature flags JSON file')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Setup') {
            steps {
                script {
                    env.BRANCH_NAME = 'dev'
                    
                    // Extract configuration file name without extension
                    env.CONFIG_FILE_NAME = params.CONFIG_FILE.replaceAll('\\.json$', '')
                    
                    env.CONFIG_VERSION = 1
                    
                    echo "Configuration file: ${env.CONFIG_FILE_NAME}"
                    echo "Environment (branch): ${env.BRANCH_NAME}"
                    echo "Configuration version: ${env.CONFIG_VERSION}"
                }
            }
        }
        
        stage('Initialize Terraform') {
            steps {
                dir('terraform') {
                    sh 'terraform init -reconfigure'
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh """
                    terraform plan \\
                      -var="environment=${env.BRANCH_NAME}" \\
                      -var="config_file_name=${env.CONFIG_FILE_NAME}" \\
                      -var="config_content=${env.CONFIG_CONTENT}" \\
                      -var="config_version=${env.CONFIG_VERSION}" \\
                      -out=tfplan
                    """
                }
            }
        }
        
        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }
        
    }
    
    post {
        success {
            echo "AWS AppConfig deployment completed successfully!"
        }
        failure {
            echo "AWS AppConfig deployment failed!"
        }
        always {
            // Clean up workspace
            cleanWs()
        }
    }
}