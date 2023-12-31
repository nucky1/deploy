#!/bin/bash


# ======================================================================================================
# Variables modificables
# ======================================================================================================

# URL del repositorio Git que deseas clonar o actualizar
url_repositorio="https://github.com/devcat-technologies/eventos-front.git"

# Repositorie branch
branch="test"


# ======================================================================================================
# Clonacion
# ======================================================================================================


# Ruta del directorio donde deseas clonar o actualizar el repositorio
directorio_destino="./files"

if [ -d $directorio_destino ]; then
  rm -r $directorio_destino
fi

directorio_actual=$(pwd)
proyecto=$(basename "$directorio_actual");


# Verifica si el directorio ya existe
if [ -d "$directorio_destino" ]; then
  echo "El directorio ya existe. Realizando 'git pull'..."
  cd "$directorio_destino"
  git pull origin && echo "Git pull completado correctamente"
else
  echo "El directorio no existe. Realizando 'git clone'..."
  git clone "$url_repositorio" "$directorio_destino" && echo "Git clone completado correctamente" && cd "$directorio_destino"
  git checkout -b $branch origin/$branch
fi

cd ..

# ======================================================================================================
# Creando dockerfile
# ======================================================================================================

if [ -e "./docker-compose.yml" ]; then
  docker-compose down
fi

echo "Creando dockerfile"

# Nombre del archivo de configuración
nombre_archivo="Dockerfile"

if [ -e "./$nombre_archivo" ]; then
  rm ./$nombre_archivo
fi



# Contenido de configuración
archivo="\
FROM node:19-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install dependencies based on the preferred package manager
COPY ./files/package.json  ./package.json

RUN npm install


# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY ./files/. .

"

# Agregar las variables de entorno al contenido de configuración
if [ -f .env ]; then
  source .env
  for variable in $(cat .env); do
    clave=$(echo "$variable" | cut -d '=' -f1)
    valor=$(echo "$variable" | cut -d '=' -f2)
    archivo="$archivo
      ENV $clave=$valor
    "
  done
else
  echo "El archivo .env no se encuentra."
fi

# Continuar con el resto del contenido de configuración
archivo="$archivo

RUN npm run build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV REACT_APP_BASE_URL=https://bmlnxtest01.catmain.local:8005/api


# set hostname to localhost
ENV HOSTNAME "0.0.0.0"

CMD [\"npm\", \"start\"]
"

# Escribe el contenido en el archivo de configuración
echo "$archivo" > "$nombre_archivo"

echo "Archivo '$nombre_archivo' creado con éxito."


# ======================================================================================================
# Se inicia la creacion del build
# ======================================================================================================

echo "Se inicia la creacion del build"


# Nombre del archivo de configuración
nombre_archivo="docker-compose.yml"

if [ -e "./$nombre_archivo" ]; then
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
    container_name: $proyecto
    restart: unless-stopped
    tty: true
    networks:
      - cat-network

networks:
  cat-network:
    driver: bridge
    name: cat-network 

"

# Escribe el contenido en el archivo de configuración

echo "$configuracion" > "$nombre_archivo" && docker-compose up -d --build --force-recreate

echo "Tu app next js esta en ejecucion."

echo "Se hace la configuracion de nginx"

# Nombre del archivo de configuración
nombre_archivo=$proyecto"_nginx.config"

if [ -e "./$nombre_archivo" ]; then
  rm ./$nombre_archivo
fi

# Contenido de configuración
configuracion="\
location /$proyecto {
  proxy_pass http://$proyecto:3000; # Nombre del contenedor de Next.js

  proxy_set_header        Upgrade \$http_upgrade;
  proxy_set_header        Connection "upgrade";
  proxy_set_header        Host \$host;
  proxy_set_header        X-Real-IP \$remote_addr;
  proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header        X-Forwarded-Proto \$scheme;
  proxy_set_header        Cookie \$http_cookie;
}

"

# Escribe el contenido en el archivo de configuración
echo "$configuracion" > "$nombre_archivo"

echo "Archivo de configuración '$nombre_archivo' creado con éxito."
