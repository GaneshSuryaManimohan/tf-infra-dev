pipeline {
    agent {
        label 'AGENT-1'
    }
    options {
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        ansiColor('xterm')
    }
    parameters {
        choice(name: 'action', choices: ['Apply', 'Destroy'], description: 'Pick something')
    }
    stages {
        stage('Init') {
            steps {
                sh """
                 cd 01-vpc
                 terraform init -reconfigure
                """
            }
        }
        stage('Plan') {
            when {
                expression {
                    params.action == 'Apply'
                }
            }
            steps {
                sh """
                 cd 01-vpc
                 terraform plan
                """
            }
        }
        stage('Deploy') {
            when {
                expression {
                    params.action == 'Apply'
                }
            }

            input {
        message "Approve Terraform Apply?"
        ok "Deploy"
    }

            steps {
                sh """
                 cd 01-vpc
                 terraform apply -auto-approve
                """
                echo "Deploying..."
            }
        }
        
        stage('Destroy') {
            when {
                expression {
                    params.action == 'Destroy'
                }
            }

            input {
        message "Approve Terraform Destroy?"
        ok "Destroy"
    }
            steps {
                sh """
                 cd 01-vpc
                 terraform destroy -auto-approve
                """
                echo "Deploying..."
            }
        }
    }
    post {
        always {
            echo 'I will always say hello'
        }
        success {
            echo 'Shows Only upon success'
            cleanWs() // this ensure to delete the workspace after build is success
        }
        failure {
            echo 'shows upon failure'
        }
    }
}