pipeline {
    agent any

    stages {

        stage('Build') {
            when {
                anyOf {
                    branch 'main'
                    branch 'development'
                    branch 'feature-*'
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
        stage('Build') {
            steps {
                script {
                    bat 'docker build -t jenkins-dev:1.0.0'
                    echo 'listing docker images...'
                    bat 'docker images'
                }
            }
        }

        stage('Publish artifacts and release tag') {
            when {
                anyOf {
                    branch 'main'
                    branch 'development'
                    branch 'feature-*'
                    changeRequest() // CHANGE_BRANCH
                }
            }
            steps {
                script {
                    if (env.CHANGE_BRANCH != null) {
                        branchName = env.CHANGE_BRANCH
                    } else {
                        branchName = env.BRANCH_NAME
                    }
                }

                withCredentials([usernamePassword(credentialsId: '4083cc2c-2d64-4782-9bfb-edef63dcd474', usernameVariable: 'username', passwordVariable: 'password')]) {
                    script {
                        echo "Calculating release and next iteration version..."
                        echo branchName
                        currentMinorVersion = powershell(returnStdout: true, script:  '.\\findLatestGitTag.ps1' + " " + branchName + "*")
                        nextIterationMinor = currentMinorVersion.toInteger() + 1
                        echo "current minor: " + currentMinorVersion
                        echo "next minor: " + nextIterationMinor
                        pom = readMavenPom(file: 'pom.xml')
                        releaseVersionAndTag = pom.version.minus('-SNAPSHOT')
                        echo "Pom version: " + releaseVersionAndTag
                        nextIterationSnapshot = pom.version
                        releaseVersionAndTag = branchName + "-" + releaseVersionAndTag
                        releaseVersionAndTag = releaseVersionAndTag.replace(".0", "." + nextIterationMinor.toString())
                        echo "New release tag: " + releaseVersionAndTag
                        bat "git checkout -b ${branchName}"
                        bat "mvn release:prepare -B -Dusername=${username} -Dpassword=${password} -DreleaseVersion=${releaseVersionAndTag} -DdevelopmentVersion=${nextIterationSnapshot} -Dtag=${releaseVersionAndTag}"
                    }
                }

                withMaven(mavenSettingsConfig: 'de1a0781-bd96-4464-a0b7-fef6480b1fb6') {
                    script {
                        bat "mvn -Darguments=-Djfrog.target=${branchName} release:perform -B"
                    }
                }
            }
        }

        stage('Deploy') {
            when {
                anyOf {
                    branch 'main'
                    branch 'development'
                    branch 'feature-*'
                    changeRequest() // CHANGE_BRANCH
                }
            }

            steps {
                script {
                    if (env.CHANGE_BRANCH != null) {
                        if (env.CHANGE_BRANCH ==~ "feature-.*") {
                            echo "Deploying to TEST..."
                        } else if (env.CHANGE_BRANCH == "development") {
                            echo "Deploying to PREP..."
                        }
                    } else {
                        if (env.BRANCH_NAME ==~ "feature-.*") {
                            echo "Deploying to DEV..."
                        } else if (env.BRANCH_NAME == "development") {
                            echo "Deploying to PREP..."
                        } else {
                            echo "Deploying to PROD..."
                        }
                    }
                }
            }
        }


        stage('Execute Test') {
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
    }
}
