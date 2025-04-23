# Etapa de build
FROM node:18-alpine as builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build --configuration=production

# Etapa de producción con nginx
FROM nginx:alpine

COPY --from=builder /app/dist/angular-test /usr/share/nginx/html

# Copiar configuración de nginx opcionalmente si existe
# COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
