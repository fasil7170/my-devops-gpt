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

* name: kaniko
  image: gcr.io/kaniko-project/executor:latest
  command: ['cat']
  tty: true
  volumeMounts:

  * name: kaniko-secret
    mountPath: /kaniko/.docker

* name: trivy
  image: aquasec/trivy:0.50.0
  command: ['cat']
  tty: true

volumes:

* name: kaniko-secret
  secret:
  secretName: docker-cred
  """
  }
  }

  environment {
  IMAGE = "fazil2664/boardshack:${BUILD_NUMBER}"
  }

  stages {

  
  stage('Checkout') {
      steps {
          git branch: 'main',
              credentialsId: 'git-cred',
              url: 'https://github.com/fasil7170/Boardgame.git'
      }
  }

  stage('Build') {
      steps {
          container('maven') {
              sh "mvn clean package -DskipTests"
          }
      }
  }

  stage('Docker Build & Push') {
      steps {
          container('kaniko') {
              sh """
              /kaniko/executor \
                --dockerfile=Dockerfile \
                --context=. \
                --destination=\$IMAGE \
                --insecure \
                --skip-tls-verify
              """
          }
      }
  }

  stage('Scan (Non-blocking)') {
      steps {
          container('trivy') {
              sh "trivy image \$IMAGE || true"
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
                  kubectl rollout status deployment/my-app --timeout=120s
                  """
              }
          }
      }
  }

  }
  }
