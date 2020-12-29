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

        stage('Publish artifacts and release tag') {
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
                        branchName = env.CHANGE_BRANCH
                    } else {
                        branchName = env.BRANCH_NAME
                    }
                    branchName = branchName.replace("/", "%2F")
                }

                withCredentials([usernamePassword(credentialsId: '4083cc2c-2d64-4782-9bfb-edef63dcd474', usernameVariable: 'username', passwordVariable: 'password')]) {
                    script {
//                        echo "PR ${env.CHANGE_BRANCH} --> ${env.CHANGE_TARGET}"
//                        echo "BRANCH ${env.BRANCH_NAME}"
                        echo "Calculating release and next iteration version..."
                        currentMinorVersion = powershell(returnStdout: true, script: '''
                    $minors = @()
                    git fetch origin
                    $TAGS = git tag --list "${branchName}"
                    foreach($tag in $TAGS) { $minors += $tag.SubString($tag.LastIndexOf(".")+1) -as [int]}
                    if ($minors.Length -eq 0) { $minors.Clear(); $minors += 0 -as [int] }
                    $minors | sort -descending | select -First 1
                         '''
                        )

                        nextIterationMinor = currentMinorVersion.toInteger() + 1
                        echo "current minor " + currentMinorVersion
                        echo "next minor    " + nextIterationMinor
                        pom = readMavenPom(file: 'pom.xml')
                        releaseVersionAndTag = pom.version.minus('-SNAPSHOT')
                        echo "Release version and tag: " + releaseVersionAndTag
                        //currentminorVersion = releaseVersionAndTag.substring(releaseVersionAndTag.lastIndexOf(".") + 1).toInteger()
//                        nextIterationMinor = currentminorVersion + 1
                        nextIterationSnapshot = pom.version
                        //.replace("0-SNAPSHOT", nextIterationMinor.toString() + "-SNAPSHOT")
                        echo "Next iteration version: " + nextIterationSnapshot
                        releaseVersionAndTag = env.BRANCH_NAME + "-" + releaseVersionAndTag
                        releaseVersionAndTag = releaseVersionAndTag.replace(".0", "." + nextIterationMinor.toString())
                        echo "release version final:    " + releaseVersionAndTag
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
                    branch 'feature/*'
                    changeRequest() // CHANGE_BRANCH
                }
            }

            steps {
                script {
                    if (env.CHANGE_BRANCH != null) {
                        if (env.CHANGE_BRANCH ==~ "feature/.*") {
                            echo "Deploying to TEST..."
                        } else if (env.CHANGE_BRANCH == "development") {
                            echo "Deploying to PREP..."
                        }
                    } else {
                        if (env.BRANCH_NAME ==~ "feature/.*") {
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

//        stage('Release and deploy to TEST env') {
//            when {
//                changeRequest()
//            }
//            steps {
//                withCredentials([usernamePassword(credentialsId: '4083cc2c-2d64-4782-9bfb-edef63dcd474', usernameVariable: 'username', passwordVariable: 'password')]) {
//                    script {
//                        echo "PR ${env.CHANGE_BRANCH} --> ${env.CHANGE_TARGET}"
//                        echo "BRANCH ${env.BRANCH_NAME}"
//                        echo "Reading pom..."
//                        pom = readMavenPom(file: 'pom.xml')
//                        echo "Calculating release and next iteration version..."
//                        releaseVersionAndTag = pom.version.minus('-SNAPSHOT')
//                        echo "Release version and tag: " + releaseVersionAndTag
//                        currentminorVersion = releaseVersionAndTag.substring(releaseVersionAndTag.lastIndexOf(".") + 1).toInteger()
//                        nextIterationMinor = currentminorVersion + 1
//                        nextInterationSnapshot = pom.version.replace(currentminorVersion.toString() + "-SNAPSHOT", nextIterationMinor.toString() + "-SNAPSHOT")
//                        echo "Next iteration version: " + nextInterationSnapshot
//                        bat "git checkout -b ${env.CHANGE_BRANCH}"
//                        // -DdevelopmentVersion=${nextInterationSnapshot}  -Dtag=${releaseVersionAndTag}
//                        bat "mvn release:prepare -B -Dusername=${username} -Dpassword=${password} -DreleaseVersion=${releaseVersionAndTag}"
//
//                    }
//                }
//
//                withMaven(mavenSettingsConfig: 'de1a0781-bd96-4464-a0b7-fef6480b1fb6') {
//                    script {
//                        bat "mvn -Darguments=-Djfrog.target=${env.CHANGE_BRANCH} release:perform -B"
//                    }
//                }
//
//                echo "Deploying to TEST env..."
//            }
//        }

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
