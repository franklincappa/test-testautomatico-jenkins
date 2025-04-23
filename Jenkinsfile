
pipeline {
    agent {
        docker {
            image 'cypress/browsers:node18.12.0-chrome107'
        }
    }

    environment {
        IMAGE_NAME = "angular-app-test"
        CONTAINER_NAME = "angular-app-test-container"
        GIT_REPO = "https://github.com/franklincappa/test-testautomatico-jenkins.git"
        GIT_BRANCH = "master"
    }

    stages {
        stage('Clonar Código') {
            steps {
                echo "Rama activa definida manualmente: ${GIT_BRANCH}"
                git branch: "${GIT_BRANCH}", url: "${GIT_REPO}"
            }
        }

        stage('Instalar dependencias') {
            steps {
                sh 'npm install'
            }
        }

        stage('Ejecutar Tests') {
            steps {
                sh 'npm test'
            }
        }

        stage('Construir Imagen') {
            steps {
                sh "docker build -t ${IMAGE_NAME} ."
            }
        }

        stage('Desplegar') {
            steps {
                sh "docker stop ${CONTAINER_NAME} || true"
                sh "docker rm ${CONTAINER_NAME} || true"
                sh "docker run -d --name ${CONTAINER_NAME} -p 5005:80 ${IMAGE_NAME}"
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline finalizado correctamente"
        }
        failure {
            echo "❌ Error en los tests o etapas previas, pipeline cancelado"
        }
    }
}
