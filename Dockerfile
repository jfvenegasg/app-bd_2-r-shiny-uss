# Descarga de una version de r del paquete tidyverse
FROM rocker/shiny-verse:latest

# Librerias de uso general
RUN apt-get update && apt-get install -y \
    curl \
    sudo \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev\
    ## Limpieza
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/ \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

# Instalar paquetes de r que sean necesarios
RUN R -e "install.packages('shiny', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('bigrquery', repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('echarts4r', repos='http://cran.rstudio.com/')"

# Limpieza
RUN rm -rf /tmp/downloaded_packages/ /tmp/*.rds

# Copiar archivos de configuracion en la imagen docker
COPY shiny-server.conf  /etc/shiny-server/shiny-server.conf

# Copiar shiny app en la imagen docker
COPY mi_app /srv/shiny-server/

RUN rm /srv/shiny-server/index.html

# Habilitar el puerto 5000 para la shiny app
EXPOSE 5000

# Copiar el archivo de ejecucion de la shiny app en la imagen docker
COPY shiny-server.sh /usr/bin/shiny-server.sh

USER shiny

CMD ["/usr/bin/shiny-server"]