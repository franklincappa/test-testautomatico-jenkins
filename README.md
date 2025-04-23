
# 🧪 Escenario 4: Tests Automáticos Antes del Build con Jenkins + Angular

Este repositorio demuestra cómo integrar una aplicación Angular en Jenkins para ejecutar **tests automáticos antes del build**, como parte de una práctica DevOps moderna.

---

## 🎯 Objetivo

- Validar que los tests (`npm test`) se ejecutan exitosamente antes de compilar o desplegar
- Cancelar el pipeline automáticamente si los tests fallan
- Desplegar la aplicación Angular en un contenedor Docker solo si las pruebas pasan

---

## 📁 Estructura del Proyecto

```
test-testautomatico-jenkins/
│
├── src/                      # Código fuente Angular
├── package.json              # Scripts de build y test
├── Dockerfile                # Construcción de imagen Angular + nginx
├── Jenkinsfile               # Pipeline de Jenkins con etapa de tests
└── README.md                 # Este archivo
```

---

## 🚀 Comandos clave en `package.json`

```json
"scripts": {
  "start": "ng serve",
  "build": "ng build",
  "test": "ng test --watch=false --browsers=ChromeHeadless"
}
```

Asegúrate de tener configurado `Karma` con `ChromeHeadless` para ejecutar los tests en CI/CD.

---

## 🐳 Dockerfile

El contenedor final se sirve con `nginx`, usando la carpeta `/dist`.

```Dockerfile
# Etapa 1: Build
FROM node:18-alpine as builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build --configuration=production

# Etapa 2: nginx
FROM nginx:alpine
COPY --from=builder /app/dist/ /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

---

## 🧩 Jenkinsfile

El pipeline en Jenkins realiza:

1. Clonación del código
2. Instalación de dependencias
3. Ejecución de tests
4. Build de imagen Docker
5. Despliegue en contenedor si todo es exitoso

```groovy
pipeline {
    agent any

    environment {
        IMAGE_NAME = "angular-app-test"
        CONTAINER_NAME = "angular-app-test-container"
        GIT_REPO = "https://github.com/franklincappa/test-testautomatico-jenkins.git"
        GIT_BRANCH = "main"
    }

    stages {
        stage('Clonar Código') {
            steps {
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
```

---

## 🌐 Acceso a la App

Una vez desplegada, accede vía:

```
http://localhost:5005
```

---

## 👨‍💻 Autor

Franklin Cappa Ticona  
DevOps Engineer - DBCODE Consulting
