pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "fazil2664/app"
        IMAGE_TAG = "${BUILD_NUMBER}"
        NEXUS_URL = "http://192.168.0.100:8081"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/fasil7170/my-devops-gpt'
            }
        }

        stage('Build & Unit Test') {
            steps {
                sh 'mvn clean verify'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'SONAR_TOKEN', variable: 'SONAR_AUTH_TOKEN')]) {
                    withSonarQubeEnv('SonarQube') {
                        sh """
                        mvn sonar:sonar \
                        -Dsonar.projectKey=my-app \
                        -Dsonar.host.url=$SONAR_HOST_URL \
                        -Dsonar.login=$SONAR_AUTH_TOKEN
                        """
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
                sh 'trivy fs . || true'
            }
        }

        stage('Package') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Docker Build') {
            steps {
                sh "docker build -t $DOCKER_IMAGE:$IMAGE_TAG ."
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh "trivy image $DOCKER_IMAGE:$IMAGE_TAG || true"
            }
        }

        stage('Docker Login & Push') {
            steps {
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

        stage('Update K8s Manifest') {
            steps {
                sh """
                sed -i 's|image:.*|image: $DOCKER_IMAGE:$IMAGE_TAG|g' k8s-manifests/deployment.yaml || true
                """
            }
        }

        stage('Push to Git') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'git-creds',
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_PASS'
                )]) {
                    sh """
                    git config user.name "jenkins"
                    git config user.email "jenkins@example.com"
                    git add .
                    git commit -m "Update image to $IMAGE_TAG" || echo "No changes"
                    git push https://$GIT_USER:$GIT_PASS@github.com/fasil7170/my-devops-gpt.git main
                    """
                }
            }
        }
    }
}
