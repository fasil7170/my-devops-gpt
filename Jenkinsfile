pipeline {
    agent {
        kubernetes {
            label 'k8s-agent'
            defaultContainer 'build'
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    args: ['\$(JENKINS_SECRET)', '\$(JENKINS_NAME)']
    volumeMounts:
    - mountPath: /home/jenkins/agent
      name: workspace-volume
  - name: build
    image: my-jenkins-agent:latest
    command: ['cat']
    tty: true
    volumeMounts:
    - mountPath: /home/jenkins/agent
      name: workspace-volume
  volumes:
  - name: workspace-volume
    emptyDir: {}
            """
        }
    }

    environment {
        DOCKER_IMAGE = "fazil2664/app"
        IMAGE_TAG = "${BUILD_NUMBER}"
        NEXUS_URL = "http://192.168.0.100:8081"
        PATH = "/usr/bin:${env.PATH}"
    }

    stages {

        stage('Checkout') {
            steps {
                container('build') {
                    git branch: 'main', url: 'https://github.com/fasil7170/my-devops-gpt'
                }
            }
        }

        stage('Build & Unit Test') {
            steps {
                container('build') {
                    sh 'mvn clean verify'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                container('build') {
                    withCredentials([string(credentialsId: 'SONAR_TOKEN', variable: 'SONAR_AUTH_TOKEN')]) {
                        withSonarQubeEnv('SonarQube') {
                            sh """
                                mvn clean verify org.sonarsource.scanner.maven:sonar-maven-plugin:4.0.0.4121:sonar \
                                    -Dsonar.projectKey=my-app \
                                    -Dsonar.host.url=$SONAR_HOST_URL \
                                    -Dsonar.login=$SONAR_AUTH_TOKEN
                            """
                        }
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                container('build') {
                    timeout(time: 10, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }

        stage('Trivy FS Scan') {
            steps {
                container('build') {
                    sh 'trivy fs --exit-code 1 --severity HIGH,CRITICAL .'
                }
            }
        }

        stage('Package') {
            steps {
                container('build') {
                    sh 'mvn clean package -DskipTests'
                }
            }
        }

        stage('Upload to Nexus') {
            steps {
                container('build') {
                    withCredentials([usernamePassword(
                        credentialsId: 'nexus-creds',
                        usernameVariable: 'NEXUS_USER',
                        passwordVariable: 'NEXUS_PASS'
                    )]) {
                        sh """
                            mvn deploy \
                                -Dnexus.url=$NEXUS_URL \
                                -Dnexus.username=$NEXUS_USER \
                                -Dnexus.password=$NEXUS_PASS
                        """
                    }
                }
            }
        }

        stage('Docker Build') {
            steps {
                container('build') {
                    sh "docker build -t $DOCKER_IMAGE:$IMAGE_TAG ."
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                container('build') {
                    sh "trivy image --exit-code 1 --severity HIGH,CRITICAL $DOCKER_IMAGE:$IMAGE_TAG"
                }
            }
        }

        stage('Docker Login & Push') {
            steps {
                container('build') {
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                            docker push $DOCKER_IMAGE:$IMAGE_TAG
                        """
                    }
                }
            }
        }

        stage('Update K8s Manifest') {
            steps {
                container('build') {
                    sh "sed -i 's|image:.*|image: $DOCKER_IMAGE:$IMAGE_TAG|g' k8s-manifests/deployment.yaml"
                }
            }
        }

        stage('Push to Git') {
            steps {
                container('build') {
                    withCredentials([usernamePassword(
                        credentialsId: 'git-creds',
                        usernameVariable: 'GIT_USER',
                        passwordVariable: 'GIT_PASS'
                    )]) {
                        sh """
                            git config user.name "jenkins"
                            git config user.email "jenkins@example.com"
                            git add .
                            git commit -m "Update image to $IMAGE_TAG" || echo "No changes to commit"
                            git push https://$GIT_USER:$GIT_PASS@github.com/fasil7170/my-devops-gpt.git main
                        """
                    }
                }
            }
        }

    }
}
