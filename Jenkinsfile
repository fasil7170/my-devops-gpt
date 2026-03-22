pipeline {
    agent {
        kubernetes {
            label 'devops-agent'
            defaultContainer 'maven'
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: maven
    image: maven:3.9.9-eclipse-temurin-17
    command: ['cat']
    tty: true

  - name: docker
    image: docker:24.0.5
    command: ['cat']
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock

  - name: trivy
    image: aquasec/trivy:latest
    command: ['cat']
    tty: true
    volumeMounts:
    - name: docker-sock   # ✅ FIX: allow trivy to access docker
      mountPath: /var/run/docker.sock

  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
"""
        }
    }

    environment {
        DOCKER_IMAGE = "fazil2664/app"
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

    stage('Clean Workspace') {
        steps {
            deleteDir()
        }

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/fasil7170/my-devops-gpt'
            }
        }

        stage('Build & Unit Test') {
            steps {
                container('maven') {
                    sh 'mvn clean package -DskipTests'   // ✅ faster & enough
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                container('maven') {
                    withCredentials([string(credentialsId: 'SONAR_TOKEN', variable: 'SONAR_AUTH_TOKEN')]) {
                        withSonarQubeEnv('SonarQube') {
                            sh """
                            mvn sonar:sonar \
                            -Dsonar.projectKey=my-app \
                            -Dsonar.login=$SONAR_AUTH_TOKEN
                            """
                        }
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: false
                }
            }
        }

        stage('Trivy FS Scan') {
            steps {
                container('trivy') {
                    sh 'trivy fs . || true'
                }
            }
        }

        stage('Docker Build') {
            steps {
                container('docker') {
                    sh "docker build -t $DOCKER_IMAGE:$IMAGE_TAG ."
                }
            }
        }

        stage('Docker Push') {
    steps {
        container('docker') {
            withCredentials([usernamePassword(
                credentialsId: 'docker-creds',
                usernameVariable: 'DOCKER_USER',
                passwordVariable: 'DOCKER_PASS'
            )]) {
                sh '''
                echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                docker push $DOCKER_IMAGE:$IMAGE_TAG
                '''
            }
         }
      }
 }

        stage('Trivy Image Scan') {   // ✅ moved AFTER push
            steps {
                container('trivy') {
                    sh "trivy image $DOCKER_IMAGE:$IMAGE_TAG || true"
                }
            }
        }
    }
}
