pipeline {
    agent any

    stages {
        stage('Build') {
            when {
                anyOf {
                    branch 'main'
                    branch 'development'
                    branch 'feature/*'
                    changeRequest()
                }

            }
            steps {
                echo "Running maven build on ${env.BRANCH_NAME}"
                echo "Running sonar check on ${env.BRANCH_NAME}"
            }
        }

        stage('Deploy to DEV') {
            steps {
                echo "Deploying image from ${env.BRANCH_NAME} to DEV cluster "
            }
        }
        stage('Test') {
            steps {
                script {
                    branchName = env.BRANCH_NAME   //filename will have the name of the file
                    branchName = branchName.replace("/", "%2F")
                }
                echo "Running smoke and feature tests from jenkins-test/${env.BRANCH_NAME}"
                build job: "jenkins-test/${branchName}", propagate: true, wait: true
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
            }
        }
    }
}