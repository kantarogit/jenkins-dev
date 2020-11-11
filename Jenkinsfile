pipeline {
    agent any

    stages {
        stage('Build') {
            when {
                anyOf {
                    branch 'main'
                    branch 'development'
                    branch 'feature/*'
                    changeRequest() // CHANGE_BRANCH
                }
            }

            steps {
                script {
                    if (env.CHANGE_BRANCH != null) {
                        echo "Running maven build on PR ${env.CHANGE_BRANCH} --> ${env.CHANGE_TARGET}"
                    } else {
                        echo "Running maven build on branch ${env.BRANCH_NAME}"
                    }
                }
                bat 'mvn clean install'
            }
        }

//        stage('Read pom') {
//            steps {
//                script {
//                    pom = readMavenPom(file: 'pom.xml')
//                    echo pom
////                    pom = bat script: 'mvn help:evaluate -Dexpression=project.version -q -DforceStdout', returnStdout: true
//
//                }
//            }
//        }

        stage('Deploy to DEV') {
            when {
                branch 'feature/*'
            }
            steps {
                script {
                    // read pom
                    echo "Reading pom..."
                    pom = readMavenPom(file: 'pom.xml')
                    echo "Publishing " + pom.version.minus('-SNAPSHOT') + " to artifactory..."
                    bat "mvn -B release:prepare release:perform"
                    echo "Deploying artifact from ${env.BRANCH_NAME} to DEV cluster..."
                }
            }
        }

        stage('Deploy to TEST') {
            when {
                changeRequest()
            }
            steps {
                script {
                    echo "PR ${env.CHANGE_BRANCH} --> ${env.CHANGE_TARGET}"
                    echo "Reading pom..."
                    pom = readMavenPom(file: 'pom.xml')
                    echo "Publishing " + pom.version.minus('-SNAPSHOT') + " to artifactory..."
                    bat "mvn -B release:prepare release:perform"
                    echo "Deploying artifact from ${env.CHANGE_BRANCH} to TEST cluster..."
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    if (env.CHANGE_BRANCH != null) {
                        branchName = env.CHANGE_BRANCH
                    } else {
                        branchName = env.BRANCH_NAME
                    }
                    branchName = branchName.replace("/", "%2F")
                }
                echo "Running smoke and feature tests from jenkins-test/${env.BRANCH_NAME}"
                build job: "jenkins-test/${branchName}", propagate: true, wait: true
            }
        }

        stage('Candidate Release') {
            when {
                branch 'development'
            }
            steps {
                echo "Maven release ${env.BRANCH_NAME}"
            }
        }

        stage('Release') {
            when {
                branch 'main'
            }
            steps {
                echo "Maven release ${env.BRANCH_NAME}"
            }
        }
    }
}