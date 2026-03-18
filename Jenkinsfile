pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "fazil2664/app"
        IMAGE_TAG = "${BUILD_NUMBER}"
        NEXUS_URL = "http://192.168.0.100:8081"
        SONARQUBE_SERVER = "SonarQube"
    }

    tools {
        maven 'maven3'   // configure in Jenkins Global Tool Config
    }

    stages {

        stage('Checkout') {
            steps {
                  git 'https://github.com/fasil7170/my-devops-gpt'
            }
        }

        stage('Build & Unit Test') {
            steps {
                sh 'mvn clean verify'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONARQUBE_SERVER}") {
                    sh '''
                    mvn sonar:sonar \
                    -Dsonar.projectKey=my-app \
                    -Dsonar.host.url=http://192.168.0.100:9000 \
                    -Dsonar.login=$sonar-token
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Trivy FS Scan') {
            steps {
                sh 'trivy fs --exit-code 1 --severity HIGH,CRITICAL .'
            }
        }

        stage('Package') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Upload to Nexus') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-creds',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {
                    sh '''
                    mvn deploy \
                    -Dnexus.url=http://192.168.0.100:8081 \
                    -Dnexus.username=$NEXUS_USER \
                    -Dnexus.password=$NEXUS_PASS
                    '''
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                docker build -t $DOCKER_IMAGE:$IMAGE_TAG .
                '''
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh 'trivy image --exit-code 1 --severity HIGH,CRITICAL $DOCKER_IMAGE:$IMAGE_TAG'
            }
        }

        stage('Docker Login & Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    docker push $DOCKER_IMAGE:$IMAGE_TAG
                    '''
                }
            }
        }

        stage('Update K8s Manifest') {
            steps {
                sh '''
                sed -i "s|image:.*|image: $DOCKER_IMAGE:$IMAGE_TAG|g" k8s-manifests/deployment.yaml
                '''
            }
        }

        stage('Push to Git') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'git-creds',
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_PASS'
                )]) {
                    sh '''
                    git config user.name "jenkins"
                    git config user.email "jenkins@example.com"

                    git add .
                    git commit -m "Update image to $IMAGE_TAG" || echo "No changes"

                    git push https://$GIT_USER:$GIT_PASS@github.com/your-repo.git main
                    '''
                }
            }
        }
    }
}
