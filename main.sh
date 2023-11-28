#!/bin/bash
docker-compose up -d --build && echo "Se dio de alta nginx y mysql."

# Ruta al directorio que deseas recorrer
directorio="./backs"

# Verificar si el directorio existe
if [ -d "$directorio" ]; then
  # Recorrer las carpetas en el directorio
  for carpeta in "$directorio"/*/; do
    if [ -d "$carpeta" ]; then
      echo "Entrando en la carpeta: $carpeta"
      
      # Recorrer los archivos .sh dentro de la carpeta
      for archivo in "$carpeta"*.sh; do
        (
          if [ -f "$archivo" ]; then
            nombre_archivo="$(basename "$archivo")"
            cd "$carpeta"
            echo "Ejecutando el archivo: $nombre_archivo"
            # Ejecutar el archivo .sh
            chmod +x "$nombre_archivo"
            bash "$nombre_archivo" && echo "Se termino de ejecutar $nombre_archivo."
            cd ".."
          fi
        )
      done
    fi
  done
else
  echo "El directorio no existe: $directorio"
fi

# Ruta al directorio que deseas recorrer
directorio="./fronts"


# Verificar si el directorio existe
if [ -d "$directorio" ]; then
  # Recorrer las carpetas en el directorio
  for carpeta in "$directorio"/*/; do
    if [ -d "$carpeta" ]; then
      echo "Entrando en la carpeta: $carpeta"
      
      # Recorrer los archivos .sh dentro de la carpeta
      for archivo in "$carpeta"*.sh; do
        (
          if [ -f "$archivo" ]; then
            nombre_archivo="$(basename "$archivo")"
            cd "$carpeta"

            echo "Ejecutando el archivo: $nombre_archivo"
            # Ejecutar el archivo .sh
            chmod +x "$nombre_archivo"
            bash "$nombre_archivo" && echo "Se termino de ejecutar $nombre_archivo."
            
            # Copiamos la configuracion de nginx
            echo "Obtenemos la configuracion de nginx."
            for archivo_config in ./*.config; do
              if [ -e "$archivo_config" ]; then
                nombre_archivo_config=$(basename "$archivo_config")
                if [ -e "./../../nginx/config/$nombre_archivo_config" ]; then
                  rm ./../../nginx/config/$nombre_archivo_config
                fi
                cp $nombre_archivo_config ./../../nginx/config/
                echo "Configuracion de nginx obtenida."
              fi
            done

            cd ".."
          fi
        )
      done
    fi
  done
else
  echo "El directorio no existe: $directorio"
fi

chmod -R 777 ./nginx/html
docker exec nginx /bin/sh -c "chmod -R 777 /etc/nginx/html"
