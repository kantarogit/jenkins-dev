pipeline {
    agent any

    stages {

        stage('Build JAR') {
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
                sh 'mvn clean install'
            }
        }

        stage('Build Docker image') {
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
                    echo "Building docker image with latest tag"
                    // sh "docker build -t jenkins-dev ."
                }
            }
        }

        stage('Publish artifacts and tag release') {
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

                //4083cc2c-2d64-4782-9bfb-edef63dcd474
                withCredentials([usernamePassword(credentialsId: '31042479-73f0-4da0-8054-53d94356e8c6', usernameVariable: 'username', passwordVariable: 'password')]) {
                    script {
                        echo "Calculating release and next iteration version..."
                        echo branchName
                        currentMinorVersion = sh(returnStdout: true, script:  './findLatestTag.sh' + " " + branchName + "*")
                        nextIterationMinor = currentMinorVersion.toInteger() + 1
                        echo "current minor: " + currentMinorVersion
                        echo "next minor: " + nextIterationMinor
                        pom = readMavenPom(file: 'pom.xml')
                        releaseVersionAndTag = pom.version.minus('-SNAPSHOT')
                        echo "Pom version: " + releaseVersionAndTag
                        nextIterationSnapshot = pom.version
                        echo "Next iteration version: " + nextIterationSnapshot
                        releaseVersionAndTag = branchName + "-" + releaseVersionAndTag
                        releaseVersionAndTag = releaseVersionAndTag.replace(".0", "." + nextIterationMinor.toString())
                        echo "New release tag: " + releaseVersionAndTag
                        sh "git checkout -b ${branchName}"
                        sh "mvn release:prepare -B -Dusername=${username} -Dpassword=${password} -DreleaseVersion=${releaseVersionAndTag} -DdevelopmentVersion=${nextIterationSnapshot} -Dtag=${releaseVersionAndTag}"
                        echo "Tagging docker image..."
                        sh "docker tag jenkins-dev:latest jenkins-dev:${releaseVersionAndTag}"
                    }
                }

                withMaven(mavenSettingsConfig: 'de1a0781-bd96-4464-a0b7-fef6480b1fb6') {
                    script {
                        echo "Publishing JAR to Artifactory"
                        sh "mvn -Darguments=-Djfrog.target=${branchName} release:perform -B"
                        echo "Publishing Docker image to harbor/aws/jfrog..."
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
