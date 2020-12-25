pipeline {
    agent any

    stages {

//        stage('Prepare next iteration version') {
//            when {
//                anyOf {
//                    branch 'development'
//                    branch 'feature/*'
//                }
//            }
//
//            steps {
//                script {
//                    pom = readMavenPom(file: 'pom.xml')
//                    if (!pom.version.contains("SNAPSHOT")) {
//                        echo pom.version
//                        pom.version = pom.version.plus("-SNAPSHOT")
//                        echo pom.version
//                        echo pom
//                    }
//                }
//            }
//        }
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
                withCredentials([usernamePassword(credentialsId: '4083cc2c-2d64-4782-9bfb-edef63dcd474', usernameVariable: 'username', passwordVariable: 'password')]) {
                    script {
                        echo "PR ${env.CHANGE_BRANCH} --> ${env.CHANGE_TARGET}"
                        echo "BRANCH ${env.BRANCH_NAME}"
                        echo "Reading pom..."
                        pom = readMavenPom(file: 'pom.xml')
                        echo "Calculating release and next iteration version..."
                        releaseVersionAndTag = pom.version.minus('-SNAPSHOT')
                        echo "Release version and tag: " + releaseVersionAndTag
                        currentminorVersion = releaseVersionAndTag.substring(releaseVersionAndTag.lastIndexOf(".") + 1).toInteger()
                        nextIterationMinor = currentminorVersion + 1
                        nextInterationSnapshot = pom.version.replace(currentminorVersion.toString() + "-SNAPSHOT", nextIterationMinor.toString() + "-SNAPSHOT")
                        echo "Next iteration version: " + nextInterationSnapshot
                        bat "git checkout -b ${env.CHANGE_BRANCH}"
                        bat "mvn release:prepare -B -Dusername=${username} -Dpassword=${password} -DdevelopmentVersion=${nextInterationSnapshot} -DreleaseVersion=${releaseVersionAndTag} -Dtag=${releaseVersionAndTag}"
                        echo "Deploying artifact from ${env.CHANGE_BRANCH} to TEST cluster..."
                    }
                }

                withMaven(mavenSettingsConfig: 'de1a0781-bd96-4464-a0b7-fef6480b1fb6') {
                    script {
                        bat "mvn release:perform -B -DjfrogTarget=${env.CHANGE_BRANCH}"
                    }
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