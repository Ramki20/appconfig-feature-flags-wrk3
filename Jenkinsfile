pipeline {
    agent any
    
    tools {
        terraform 'Terraform' // Use the name configured in Global Tool Configuration
    }
    
    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_DEFAULT_REGION    = 'us-east-1'
        CONFIG_DIR            = 'config'
    }
    
    parameters {
        string(name: 'CONFIG_FILE', defaultValue: 'tst3_feature_flags.json', description: 'Name of the feature flags JSON file')
        booleanParam(name: 'PRESERVE_VALUES', defaultValue: true, description: 'Preserve existing flag values')
    }
    
    stages {
        stage('Install Prerequisites') {
            steps {
                script {
                    // Check if jq is installed, if not, install it
                    def jqInstalled = sh(script: 'which jq || echo "not installed"', returnStdout: true).trim()
                    if (jqInstalled == "not installed") {
                        echo "Installing jq..."
                        sh 'apt-get update && sudo apt-get install -y jq'
                    } else {
                        echo "jq is already installed"
                    }
                    
                    // Check if AWS CLI is installed, if not, install it
                    def awsInstalled = sh(script: 'which aws || echo "not installed"', returnStdout: true).trim()
                    if (awsInstalled == "not installed") {
                        echo "Installing AWS CLI..."
                        
                        // Try to install using apt
                        sh '''
                        apt-get update
                        apt-get install -y awscli
                        '''
                        
                        // Verify AWS CLI installation
                        def awsVerify = sh(script: 'which aws || echo "not installed"', returnStdout: true).trim()
                        if (awsVerify == "not installed") {
                            echo "AWS CLI not available via apt. Installing AWS CLI v2 from AWS directly..."
                            sh '''
                            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                            unzip -o awscliv2.zip
                            ./aws/install
                            echo "export PATH=\$PATH:/usr/local/bin" >> ~/.bashrc
                            export PATH=\$PATH:/usr/local/bin
                            '''
                        }
                        
                        // Final verification
                        sh 'aws --version || echo "AWS CLI installation failed"'
                    } else {
                        echo "AWS CLI is already installed"
                    }
                }
            }
        }
        
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Setup') {
            steps {
                script {
                    env.BRANCH_NAME = env.BRANCH_NAME ?: 'dev'
                    
                    // Extract configuration file name without extension
                    env.CONFIG_FILE_NAME = params.CONFIG_FILE.replaceAll('\\.json$', '')
                    
                    // Set config version
                    env.CONFIG_VERSION = 1
                    
                    echo "Configuration file: ${env.CONFIG_FILE_NAME}"
                    echo "Environment (branch): ${env.BRANCH_NAME}"
                    echo "Configuration version: ${env.CONFIG_VERSION}"
                    
                    // Create working directory for merged config
                    sh "mkdir -p ${WORKSPACE}/merged_config"
                }
            }
        }
        
        stage('Fetch Current Configuration') {
            when {
                expression { return params.PRESERVE_VALUES }
            }
            steps {
                script {
                    // First, check if the application, configuration profile, and hosted config already exist
                    def appExists = sh(script: "aws appconfig list-applications --query \"Items[?Name=='${env.CONFIG_FILE_NAME}'].Id\" --output text || echo ''", returnStdout: true).trim()
                    
                    if (appExists && appExists != "None" && appExists != "") {
                        echo "Application exists. Fetching current configuration..."
                        
                        // Get the application ID
                        def applicationId = sh(script: "aws appconfig list-applications --query \"Items[?Name=='${env.CONFIG_FILE_NAME}'].Id\" --output text", returnStdout: true).trim()
                        
                        // Get the configuration profile ID
                        def configProfileId = sh(script: "aws appconfig list-configuration-profiles --application-id ${applicationId} --query \"Items[?Name=='${env.CONFIG_FILE_NAME}'].Id\" --output text || echo ''", returnStdout: true).trim()
                        
                        if (applicationId && configProfileId && configProfileId != "None" && configProfileId != "") {
                            // Get the latest configuration version
                            def latestVersionNumber = sh(script: "aws appconfig list-hosted-configuration-versions --application-id ${applicationId} --configuration-profile-id ${configProfileId} --query 'Items[0].VersionNumber' --output text || echo ''", returnStdout: true).trim()
                            
                            if (latestVersionNumber && latestVersionNumber != "None" && latestVersionNumber != "") {
                                // Retrieve the current configuration content
                                sh """
                                aws appconfig get-hosted-configuration-version \\
                                    --application-id ${applicationId} \\
                                    --configuration-profile-id ${configProfileId} \\
                                    --version-number ${latestVersionNumber} \\
                                    ${WORKSPACE}/merged_config/current_config.json
                                """
                                
                                // Extract the content from the response (skip the metadata)
                                sh "cat ${WORKSPACE}/merged_config/current_config.json | jq '.Content | fromjson' > ${WORKSPACE}/merged_config/current_config_content.json"
                                
                                echo "Successfully retrieved current configuration."
                            } else {
                                echo "No hosted configuration versions found. Using local configuration file."
                                sh "cp ${CONFIG_DIR}/${params.CONFIG_FILE} ${WORKSPACE}/merged_config/current_config_content.json"
                            }
                        } else {
                            echo "Application or Configuration Profile not found. Using local configuration file."
                            sh "cp ${CONFIG_DIR}/${params.CONFIG_FILE} ${WORKSPACE}/merged_config/current_config_content.json"
                        }
                    } else {
                        echo "Application does not exist yet. Using local configuration file."
                        sh "cp ${CONFIG_DIR}/${params.CONFIG_FILE} ${WORKSPACE}/merged_config/current_config_content.json"
                    }
                }
            }
        }
        
        stage('Merge Configuration') {
            when {
                expression { return params.PRESERVE_VALUES }
            }
            steps {
                script {
                    // Create a merged configuration that preserves current values but updates structure
                    sh """
                    # Extract current values section
                    cat ${WORKSPACE}/merged_config/current_config_content.json | jq '.values' > ${WORKSPACE}/merged_config/current_values.json
                    
                    # Get new flags definition
                    cat ${CONFIG_DIR}/${params.CONFIG_FILE} | jq '.flags' > ${WORKSPACE}/merged_config/new_flags.json
                    
                    # Merge: Use new flags structure, but preserve existing values where applicable
                    jq -s '
                        . as [\$new, \$current] | 
                        \$new | 
                        .flags = \$new.flags | 
                        .values = (
                            \$new.flags | keys | reduce .[] as \$f ({}; 
                                if \$current.values[\$f] != null then 
                                    .[\$f] = \$current.values[\$f] 
                                else 
                                    .[\$f] = \$new.values[\$f] 
                                end
                            )
                        ) |
                        .version = "${env.CONFIG_VERSION}"
                    ' ${CONFIG_DIR}/${params.CONFIG_FILE} ${WORKSPACE}/merged_config/current_config_content.json > ${WORKSPACE}/merged_config/merged_config.json
                    
                    # Replace the original file with the merged version
                    cp ${WORKSPACE}/merged_config/merged_config.json ${WORKSPACE}/merged_config/final_config.json
                    """
                    
                    // Use the merged configuration for deployment
                    env.CONFIG_CONTENT = sh(script: "cat ${WORKSPACE}/merged_config/final_config.json | jq -c .", returnStdout: true).trim()
                    
                    // Save the merged configuration for debugging
                    writeFile file: "${WORKSPACE}/merged_config/final_config.json", text: env.CONFIG_CONTENT
                }
            }
        }
        
        stage('Prepare Configuration') {
            when {
                expression { return !params.PRESERVE_VALUES }
            }
            steps {
                script {
                    // If not preserving values, use the original file directly
                    sh "cp ${CONFIG_DIR}/${params.CONFIG_FILE} ${WORKSPACE}/merged_config/final_config.json"
                    
                    // Update the version in the file
                    sh """
                    jq '.version = "${env.CONFIG_VERSION}"' ${WORKSPACE}/merged_config/final_config.json > ${WORKSPACE}/merged_config/temp.json
                    mv ${WORKSPACE}/merged_config/temp.json ${WORKSPACE}/merged_config/final_config.json
                    """
                    
                    env.CONFIG_CONTENT = sh(script: "cat ${WORKSPACE}/merged_config/final_config.json | jq -c .", returnStdout: true).trim()
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
                      -var="feature_flags_file_path=${WORKSPACE}/merged_config/final_config.json" \\
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
            
            // Optionally, archive the merged configuration for reference
            archiveArtifacts artifacts: "merged_config/final_config.json", allowEmptyArchive: true
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