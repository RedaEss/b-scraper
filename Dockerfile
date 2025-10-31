# Dockerfile
FROM rocker/r-ver:4.3.1

# Installation des dépendances système
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copie et installation des packages
COPY requirements.R .
RUN Rscript requirements.R

# Installation supplémentaire pour JSON
RUN R -e "install.packages('jsonlite', dependencies = TRUE)"

# Copie des scripts
COPY scraper.R .
COPY run_scraper.R .

# Commande par défaut
CMD ["Rscript", "run_scraper.R"]