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
    image: docker:24.0
    command: ['cat']
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock

  - name: trivy
    image: aquasec/trivy:0.50.0
    command: ['cat']
    tty: true

  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
"""
        }
    }

    tools {
        jdk 'jdk11'
        maven 'maven3'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }

    stages {

        stage('Git Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'git-cred',
                    url: 'https://github.com/fasil7170/Boardgame.git'
            }
        }

        stage('Compile') {
            steps {
                container('maven') {
                    sh "mvn compile"
                }
            }
        }

        stage('Test') {
            steps {
                container('maven') {
                    sh "mvn test"
                }
            }
        }

        stage('File System Scan') {
            steps {
                container('trivy') {
                    sh "trivy fs --format table -o trivy-fs-report.html ."
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                container('maven') {
                    withSonarQubeEnv('sonar') {
                        sh """
                        $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=BoardGame \
                        -Dsonar.projectKey=BoardGame \
                        -Dsonar.java.binaries=.
                        """
                    }
                }
            }
        }

        stage('Build') {
            steps {
                container('maven') {
                    sh "mvn package"
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                container('docker') {
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-cred',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                        echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                        docker build -t fazil2664/boardshack:latest .
                        docker push fazil2664/boardshack:latest
                        """
                    }
                }
            }
        }

        stage('Docker Image Scan') {
            steps {
                container('trivy') {
                    sh "trivy image --format table -o trivy-image-report.html fazil2664/boardshack:latest"
                }
            }
        }

        stage('Deploy To Kubernetes') {
            steps {
                container('maven') {
                    withKubeConfig(credentialsId: 'k8-cred') {
                        sh "kubectl apply -f deployment-service.yaml"
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                container('maven') {
                    withKubeConfig(credentialsId: 'k8-cred') {
                        sh "kubectl get pods -n webapps"
                        sh "kubectl get svc -n webapps"
                    }
                }
            }
        }
    }

    post {
        always {
            emailext (
                subject: "Build: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Check build at ${env.BUILD_URL}",
                to: 'rkf@gmail.com',
                attachmentsPattern: 'trivy-image-report.html'
            )
        }
    }
}
