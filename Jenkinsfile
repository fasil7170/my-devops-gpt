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

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }

    stages {

        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Git Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'git-cred',
                    url: 'https://github.com/fasil7170/Boardgame.git'
            }
        }

        stage('Verify Java') {
            steps {
                container('maven') {
                    sh "java -version"
                    sh "mvn -version"
                }
            }
        }

        stage('Check POM') {
            steps {
                sh "cat pom.xml"
            }
        }

        stage('Compile') {
            steps {
                container('maven') {
                    sh "mvn clean install -U"
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
                    sh "trivy image fazil2664/boardshack:latest"
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
    }
}
