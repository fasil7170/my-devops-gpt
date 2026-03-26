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

* name: maven
  image: maven:3.9.9-eclipse-temurin-17
  command: ['cat']
  tty: true

* name: docker
  image: docker:24.0
  command: ['cat']
  tty: true
  volumeMounts:

  * name: docker-sock
    mountPath: /var/run/docker.sock

* name: trivy
  image: aquasec/trivy:0.50.0
  command: ['cat']
  tty: true

volumes:

* name: docker-sock
  hostPath:
  path: /var/run/docker.sock
  """
  }
  }

  environment {
  IMAGE = "fazil2664/boardshack:${BUILD_NUMBER}"
  }

  stages {

  ```
  stage('Clean Workspace') {
      steps {
          cleanWs()
      }
  }

  stage('Git Checkout') {
      steps {
          retry(2) {
              git branch: 'main',
                  credentialsId: 'git-cred',
                  url: 'https://github.com/fasil7170/Boardgame.git'
          }
      }
  }

  stage('Build') {
      steps {
          container('maven') {
              sh "mvn clean install -DskipTests"
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
                  docker build -t \$IMAGE .
                  docker push \$IMAGE
                  """
              }
          }
      }
  }

  stage('Security Scan') {
      steps {
          container('trivy') {
              sh "trivy image --exit-code 1 --severity HIGH,CRITICAL \$IMAGE"
          }
      }
  }

  stage('Deploy') {
      steps {
          container('maven') {
              withKubeConfig(credentialsId: 'k8-cred') {
                  sh """
                  sed -i 's|IMAGE_PLACEHOLDER|\$IMAGE|g' deployment-service.yaml
                  kubectl apply -f deployment-service.yaml
                  kubectl rollout status deployment/my-app
                  """
              }
          }
      }
  }
  ```

  }
  }
