#!/bin/bash
directorio_actual=$(pwd)
proyecto=$(basename "$directorio_actual");
# ======================================================================================================
# Variables modificables
# ======================================================================================================

# URL del repositorio Git que deseas clonar o actualizar
url_repositorio="https://github.com/nucky1/back-financiacion.git"

# Repositorie branch
BRANCH="test"

# Backend port
PORT="8201"

# Ambiente
NODE_ENV="test"

# Base de datos
DATABASE="financiacion"

# Server URL
SERVER="https://test.monic.com.ar"

# ======================================================================================================
# Clonamos o pulleamos el repositorio
# ======================================================================================================

# Ruta del directorio donde deseas clonar o actualizar el repositorio
directorio_destino="./files"

if [ -d $directorio_destino ]; then
  rm -r $directorio_destino
fi

# Verifica si el directorio ya existe
if [ -d "$directorio_destino" ]; then
  echo "El directorio ya existe. Realizando 'git pull'..."
  cd "$directorio_destino"
  git pull origin && echo "Git pull completado correctamente"
else
  echo "El directorio no existe. Realizando 'git clone'..."
  git clone "$url_repositorio" "$directorio_destino" && echo "Git clone completado correctamente" && cd "$directorio_destino"
  git checkout -b $BRANCH origin/$BRANCH
fi

cd ..

# ======================================================================================================
# Crea dockerfile
# ======================================================================================================

echo "Creando dockerfile"

# Nombre del archivo de configuración
nombre_archivo="Dockerfile"

if [ -e "./$nombre_archivo" ]; then
  rm ./$nombre_archivo
fi

# Contenido de configuración
configuracion="\
FROM node:19

# Create app directory
WORKDIR /back

# Install app dependencies
COPY ./files/package*.json ./

# Necesario para instalar puppeter sin problemas
ENV PUPPETEER_SKIP_DOWNLOAD=true

# Variables de entorno
ENV PORT=$PORT
ENV NODE_ENV=$NODE_ENV

RUN npm install --legacy-peer-deps

# Copy app source code
COPY ./files/. .

#Expose port and start application
EXPOSE $PORT

CMD [ \"npx\", \"nodemon\" ,\"app.js\" ]
"

# Escribe el contenido en el archivo de configuración
echo "$configuracion" > "$nombre_archivo"

echo "Archivo de configuración '$nombre_archivo' creado con éxito."

# ======================================================================================================
# Crea build
# ======================================================================================================

echo "Se inicia la creacion del build"

# Nombre del archivo de configuración
nombre_archivo="docker-compose.yml"

if [ -e "./$nombre_archivo" ]; then
  docker-compose down -v
  rm ./$nombre_archivo
fi

# Contenido de configuración
configuracion="\
version: \"3.8\"

services:
  $proyecto:
    build:
      context: .
      dockerfile: Dockerfile
    restart: always
    tty: true
    networks:
      - monic-network
    volumes:
      - ../../nginx/certs:/back/certs
    ports:
      - $PORT:$PORT

networks:
  monic-network:
    driver: bridge
    name: monic-network
"

# Escribe el contenido en el archivo de configuración

echo "$configuracion" > "$nombre_archivo"

echo "El back $proyecto esta en ejecucion."

# ======================================================================================================
# Crea la base de datos
# ======================================================================================================

docker exec db /bin/sh -c "until mysqladmin ping -h 'localhost' -ufinadmin -p3s74EsL4Cl4v3; do echo 'MySQL aún no está disponible...'; sleep 2; done && mysql -h 'localhost' -uroot -pMnBvCxZqWeRtY102938\! -e 'CREATE DATABASE IF NOT EXISTS $DATABASE;'"

# ======================================================================================================
# Corremos nuestro back
# ======================================================================================================

docker-compose up -d --build --force-recreate
