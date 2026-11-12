FROM php:8.3-apache

# Instalar extensiones del sistema necesarias
RUN apt-get update && apt-get install -y \
    libsqlite3-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    curl \
    && docker-php-ext-install pdo_sqlite zip pcntl bcmath \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configurar Apache para Laravel
RUN a2enmod rewrite
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
RUN sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# Instalar Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copiar el código del proyecto limpio
COPY . .

# Instalar dependencias ignorando requerimientos de plataforma estrictos
RUN composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs

# Crear base de datos SQLite y dar permisos
RUN touch database/database.sqlite \
    && chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache /var/www/html/database

EXPOSE 80

CMD php artisan migrate:fresh --seed --force && apache2-foreground