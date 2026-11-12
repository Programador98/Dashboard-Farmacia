# --- ETAPA 1: Compilar Vue 3 + Tailwind CSS con Node.js ---
FROM node:20 AS node_build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# --- ETAPA 2: Servidor PHP + Apache ---
FROM php:8.2-apache

# Instalar extensiones necesarias de PHP para Laravel y SQLite
RUN apt-get update && apt-get install -y \
    libsqlite3-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    curl \
    && docker-php-ext-install pdo_sqlite zip pcntl bcmath \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configurar Apache para Laravel (Rewrite y DocumentRoot en /public)
RUN a2enmod rewrite
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
RUN sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copiar el proyecto y los archivos compilados del frontend
COPY . .
COPY --from=node_build /app/public/build ./public/build

# Instalar dependencias de PHP optimizadas para producción
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Crear base de datos SQLite y dar permisos de escritura
RUN touch database/database.sqlite \
    && chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache /var/www/html/database

EXPOSE 80

# Iniciar migraciones y arrancar el servidor web
CMD php artisan migrate:fresh --seed --force && apache2-foreground