
pipeline {
  agent any

  environment {
    BRANCH_NAME = 'master'
    IMAGE_NAME = 'angular-app-test'
    CONTAINER_NAME = 'angular-app-test-container'
    HOST_PORT = '5005'
    CONTAINER_PORT = '80'
  }

  stages {
    stage('Clonar Código') {
      steps {
        echo "Rama activa definida manualmente: ${env.BRANCH_NAME}"
        git branch: "${env.BRANCH_NAME}", url: 'https://github.com/franklincappa/test-testautomatico-jenkins.git'
      }
    }

    stage('Instalar dependencias') {
      agent {
        docker {
          image 'cypress/browsers:node18.12.0-chrome107'
        }
      }
      steps {
        sh 'npm install'
      }
    }

    stage('Ejecutar Tests') {
      agent {
        docker {
          image 'cypress/browsers:node18.12.0-chrome107'
        }
      }
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
        script {
          sh "docker stop ${CONTAINER_NAME} || true"
          sh "docker rm ${CONTAINER_NAME} || true"
          sh "docker run -d --name ${CONTAINER_NAME} -p ${HOST_PORT}:${CONTAINER_PORT} ${IMAGE_NAME}"
        }
      }
    }
  }

  post {
    failure {
      echo "❌ Error en los tests o etapas previas, pipeline cancelado"
    }
    success {
      echo "✅ Despliegue completado con éxito: http://localhost:${HOST_PORT}"
    }
  }
}
