# 🧪 Escenario 4: Tests Automáticos Antes del Build con Jenkins + Angular

Este repositorio demuestra cómo integrar una aplicación Angular en Jenkins para ejecutar **tests automáticos antes del build**, como parte de una práctica DevOps moderna.

---

## 🎯 Objetivo

- Validar que los tests (`npm test`) se ejecutan exitosamente antes de compilar o desplegar
- Cancelar el pipeline automáticamente si los tests fallan
- Desplegar la aplicación Angular en un contenedor Docker solo si las pruebas pasan

---

## ✅ Requisitos

### 🔌 Plugins requeridos en Jenkins

Para que este pipeline funcione correctamente, asegúrate de tener instalados los siguientes plugins en Jenkins:

| Plugin                | Descripción                                       |
|-----------------------|---------------------------------------------------|
| **Docker Pipeline**   | Permite usar `agent docker` en Jenkinsfiles      |
| **Pipeline**          | Soporte general para `Declarative Pipelines`     |
| **Git plugin**        | Clonación y operaciones Git                      |
| **Pipeline: GitHub**  | Soporte para repositorios GitHub (opcional)      |
| **Email Extension**   | (opcional) Envío de notificaciones por correo    |
| **Blue Ocean**        | (opcional) para vista moderna                    |

Puedes instalarlos desde **Manage Jenkins > Manage Plugins > Available**.

Si `Docker Pipeline` no aparece, ve a la pestaña **Advanced** y haz clic en **Check Now** para refrescar el catálogo.

### ⚙️ Requisitos del entorno:
- Jenkins ejecutándose con Docker y acceso al socket `/var/run/docker.sock`
- Acceso a Internet para clonar el repositorio
- Node.js y Chrome embebidos en la imagen usada para ejecutar los tests

---

## 📁 Estructura del Proyecto

```
test-testautomatico-jenkins/
│
├── src/                      # Código fuente Angular
├── package.json              # Scripts de build y test
├── karma.conf.js
├── Dockerfile                # Construcción de imagen Angular + nginx
├── Jenkinsfile               # Pipeline de Jenkins con etapa de tests
└── README.md                 # Este archivo
```

---
## 馃З Configuraci贸n

### `karma.conf.js`

```js
process.env.CHROME_BIN = require('puppeteer').executablePath();

module.exports = function (config) {
  config.set({
    basePath: '',
    frameworks: ['jasmine', '@angular-devkit/build-angular'],
    plugins: [
      require('karma-jasmine'),
      require('karma-chrome-launcher'),
      require('karma-jasmine-html-reporter'),
      require('karma-coverage'),
      require('@angular-devkit/build-angular/plugins/karma')
    ],
    client: {
      clearContext: false
    },
    coverageReporter: {
      dir: require('path').join(__dirname, './coverage'),
      subdir: '.',
      reporters: [{ type: 'html' }, { type: 'text-summary' }]
    },
    reporters: ['progress', 'kjhtml'],
    port: 9876,
    colors: true,
    logLevel: config.LOG_INFO,
    autoWatch: false,
    customLaunchers: {
      ChromeHeadlessNoSandbox: {
        base: 'ChromeHeadless',
        flags: ['--no-sandbox']
      }
    },
    browsers: ['ChromeHeadlessNoSandbox'],
    singleRun: true,
    restartOnFileChange: false
  });
};
```

Agrega este archivo en la raíz del proyecto Angular:

📁Ubicación: `./karma.conf.js`

Contiene configuración para correr los tests con `ChromeHeadless` sin instalar Puppeteer ni Chrome manualmente.


### 🚀 Comandos clave en `package.json`

```json
"scripts": {
  "start": "ng serve",
  "build": "ng build",
  "test": "ng test --watch=false --browsers=ChromeHeadlessNoSandbox"
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

El pipeline define las siguientes etapas:

- `Clonar Código`: desde rama `master`
- `Instalar dependencias`: con imagen `cypress/browsers:node18.12.0-chrome107`
- `Ejecutar Tests`: ejecuta `npm test` con Chrome Headless No Sandbox
- `Construir Imagen`: ejecuta `docker build`
- `Desplegar`: detiene y recrea el contenedor, exponiendo en el puerto `5005` del host

```groovy

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

```

---

## ⚙️ Agente Docker

Este pipeline usa un contenedor Docker temporal con Node.js (`node:18-alpine`) como entorno de ejecución, lo que permite correr `npm install`, `npm test`, y otros comandos sin necesidad de instalar Node.js en el host Jenkins.

---

## 🌿 Detección automática de la rama (`env.BRANCH_NAME`)

Para que el pipeline funcione correctamente con cualquier rama activa, se utiliza la variable interna de Jenkins:

```groovy
git branch: "${env.BRANCH_NAME}", url: "${GIT_REPO}"
```

Esto evita tener que modificar manualmente la rama en cada ejecución.

---

## 🌐 Acceso a la App

Una vez desplegada, accede vía:

```
http://localhost:5005
```

---

## 📝 Comando para forzar fallo en tests

Modifica temporalmente un test en `*.spec.ts` para que falle:

```ts
expect(true).toBe(false);
```

Esto demostrará que el pipeline se detiene correctamente antes del `build` si hay errores en los tests.

---

## 🧪 Resultado esperado

- Si los tests **pasan** → la app se construye y despliega correctamente.
- Si los tests **fallan** → se cancela el proceso y no se genera ni despliega la imagen Docker.

---

## 👨‍💻 Autor

Franklin Cappa Ticona  
DevOps Engineer · DBCODE Consulting
