
pipeline {
  agent any

  environment {
    IMAGE_NAME = "angular-app-test"
    CONTAINER_NAME = "angular-app-container"
    GIT_REPO = "https://github.com/franklincappa/test-testautomatico-jenkins.git"
    BRANCH_NAME = "master"
  }

  stages {
    stage('Clonar Código') {
      steps {
        git branch: "${BRANCH_NAME}", url: "${GIT_REPO}"
      }
    }

    stage('Instalar dependencias y test') {
      agent {
        docker {
          image 'cypress/browsers:node18.12.0-chrome107'
          args '--user 1000:1000'
        }
      }
      steps {
        sh 'npm install'
        sh 'npm test'
      }
    }

    stage('Construir Imagen') {
      steps {
        // Esta parte sí se ejecuta en el host Jenkins
        sh "docker build -t ${IMAGE_NAME} ."
      }
    }

    stage('Desplegar') {
      steps {
        sh "docker stop ${CONTAINER_NAME} || true"
        sh "docker rm ${CONTAINER_NAME} || true"
        sh "docker run -d --name ${CONTAINER_NAME} -p 5005:5005 ${IMAGE_NAME}"
      }
    }
  }

  post {
    failure {
      echo "❌ Error en los tests o etapas previas, pipeline cancelado"
    }
  }
}
