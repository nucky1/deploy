===================================================================================================
    # Docker - Projects
===================================================================================================

Proyecto que dockeriza todo nuestros proyectos, de forma que un ejecutable levanta toda nuestra red de proyectos.

Actualmente se encuentran, financiacion.

===================================================================================================
    # Estructura Principal
===================================================================================================

|
├── backs
|   |    
|   ├── financiacion-back
|   |   |
|   |   ├── docker.sh
|   |
|   ├── ...
|
├── fronts
|   |
|   ├── financiacion
|   |   |
|   |   ├── docker.sh
|   |
|   ├── ...
|
├── nginx
|   |
|   ├── certs
|   |   |
|   |   ├── ...
|   |
|   ├── config
|   |   |
|   |   ├── ...
|   |
|   ├── html
|   |   |
|   |   ├── ...
|   |
|   ├── nginx.config
|   |
├── docker-compose.yml
|
├── main.sh


===================================================================================================
    # Funcionamiento
===================================================================================================

    El funcionamiento del proyecto comienza en "main.sh" (observable en la estructura), el mismo va a recorrer nuestras dos carpetas
"backs" y "fronts" en este respectivo orden y a ejecutar los archivos "docker.sh", pero antes de esto levantara nuestro docker principal 
con NGINX y la base de datos que mantendra todas las bases de datos de nuestros proyectos.

    La configuracion del servidor NGINX esta hecha para que tome como volumen todos los proyectos que luego se depositaran en la carpeta 
"html", y agregara a su configuracion cada archivo que se agregue a la carpeta "config". De esta manera su configuracion se producira
de forma dinamica a medida que se vayan ejecutando los archivos "docker.sh". Ademas, esta configurado para tomar los archivos de
certificados de la carpeta certs (certificados especificos de la companía) y para que las request al puerto 80 (http) se redirijan al 
puerto 443 (https).

    Los archivos "docker.sh" estan preparados para funcionar de forma atomica, es decir sin necesidad de ejecutar "main.sh", de esta forma
levantaremos un unico proyecto. A la hora de crear un nuevo archivo de este tipo solo deberemos de fijarnos en modificar su seccion de
variables modificables o su seccion de creacion del Dockerfile en caso de tener un tratamiento especial.

===================================================================================================
    # Docker.sh
===================================================================================================

    Se dividen en varias secciones, tengamos en cuenta que los archivos necesarios para levantar el contenedor se crean en periodo de ejecucion del archivo,
esto para que los mismos se creen en base a las "Variables Modificables":

*   Variables Modificables:
        Estas mismas son las tendremos que modificar si o si de proyecto a proyecto.

*   Clonacion:
        Se encargar de hacer la clonacion del repositorio del proyecto (la url del mismo se encuentra en la seccion "Variables Modificables")

*   Crea Dockerfile:
        Como su nombre lo dice esta parte creara el Dockerfile necesario para levantar la imagen del contenedor, en base a las variable modificables en caso de ser 
        necesario. Esta parte se puede modificar en caso de que el proyecto necesite un tratamiento especial, es el caso de catnet para su despliegue con Next JS, tambien es el caso 
        de evaluacion-back por el hecho de necesitar la instalacion del la libreria "puppeteer" que necesita un tratamiento extra.

*   Crea Build:
        En esta parte se procedera a levantar el proyecto, en algunos casos solo crea la carpeta de build y la mueve a la carpeta html de nginx para que la tome y en otros
        crea un archivo docker-compose para poner a correr como servidor el back o front dependiendo el caso.

*   Crea la base de datos: (Solo backs)
        En los casos de los backs que es necesario crear una base de datos, tiene una seccion que añade la base de datos si la misma no existe.

*   Corremos nuestro proyecto:
        Ultimo paso que se encarga de poner a correr el proyecto.
        
===================================================================================================
    # ¿Como agregamos un nuevo proyecto?
===================================================================================================

    Para agregar un nuevo proyecto es sencillo, tomaremos de plantilla un proyecto ya creado que se asemeje a nuestro proyecto. Si es un front creado con
create-react-app, podremos tomar evaluacion o tools. Si esta creado con Next JS podremos tomar catnet. Todos los backs son similares ya que todos esta creados con
Node JS, un caso especial tratado en los backs es en evaluacion que tiene consigo la instalacion de "puppeteer". Y luego de esto solo deberemos modificar las secciones de
"Varibles Modificables" y "Crea Dockerfile" en caso de ser necesario.

Cosas a tener en cuenta:
    *   En los backs, el nombre de la carpeta debera ser el mismo que el front mas la terminacion "-back", esto porque lo utilizaremos para crear un archivo en el front 
        con variables de entorno como la URL a la que debera pegarle para llegar al back

    *   En los fronts, el nombre de la carpeta es el nombre con que se desplegara en su conexion en NGINX, es decir si yo llamo a mi carpeta "tools", el acceso al sitio sera
        "https://server/tools"

    *   La configuracion de tu dase de datos en tu proyecto debera verse de esta manera, donde NODE_ENV lo definiremos en el "docker.sh" y el nombre de la base de datos tambien:
        "NODE_ENV": {
            "username": "root",
            "password": "**********",
            "database": "nombre_db",
            "host": "db",
            "logging": false,
            "dialect": "mysql"
        },
    
    * En caso de necesitar variables de entorno en el back, declarlas en la creacion del dockerfile del mismo como "PORT" o "NODE_ENV".


===================================================================================================
    # PUERTOS EN USO
===================================================================================================

    - 3306  : mysql
    - 80    : NGINX (http)
    - 443   : NGINX (https)
    - 8201  : financiacion-back
    - 3000  : financiacion


===================================================================================================
    # Despliegue
===================================================================================================

    A la hora de desplegarlo en un servidor nuevo, solo deberemos de tener en cuenta de remplazar la variable "server" de los backs, y ademas correr unicamente
el main.sh.
    En caso de solo querer correr un proyecto, lo podremos hacer ejecutando unicamente el docker.sh de ese mismo proyecto. Para asi no afectar lo demas que ya se
encuentra corriendo.
        
