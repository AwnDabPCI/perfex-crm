FROM php:8.2-apache

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    unzip \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libxml2-dev \
    libonig-dev \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions - only essential ones
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/* && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    zip \
    gd \
    xml \
    mbstring \
    bcmath

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Enable Apache modules
RUN a2enmod rewrite && \
    a2enmod headers && \
    a2enmod env

# Set ServerName to suppress Apache warning
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
    mkdir -p /var/run/apache2 /var/log/apache2 && \
    sed -i 's|^DefaultRuntimeDir.*|DefaultRuntimeDir /var/run/apache2|' /etc/apache2/apache2.conf && \
    sed -i 's|\${APACHE_RUN_DIR}|/var/run/apache2|g' /etc/apache2/apache2.conf && \
    sed -i 's|\${APACHE_PID_FILE}|/var/run/apache2/apache2.pid|g' /etc/apache2/apache2.conf && \
    sed -i 's|\${APACHE_RUN_USER}|www-data|g' /etc/apache2/apache2.conf && \
    sed -i 's|\${APACHE_RUN_GROUP}|www-data|g' /etc/apache2/apache2.conf && \
    sed -i 's|\${APACHE_LOG_DIR}|/var/log/apache2|g' /etc/apache2/apache2.conf && \
    find /etc/apache2 -type f -name "*.conf" -exec sed -i 's|\${APACHE_LOG_DIR}|/var/log/apache2|g' {} \;

WORKDIR /var/www/html

# Copy project files
COPY . .

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Remove install folder for production security
RUN rm -rf install/

# Install PHP dependencies
RUN cd application && \
    composer install --no-dev --no-interaction --optimize-autoloader --ignore-platform-req=ext-imap && \
    cd ..

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html && \
    find /var/www/html -type f -name "*.php" -exec chmod 644 {} \; && \
    find /var/www/html -type d -exec chmod 755 {} \; && \
    chmod -R 777 uploads && \
    chmod -R 777 temp && \
    chmod -R 777 media && \
    chmod -R 777 application/logs && \
    chmod -R 777 application/cache && \
    chmod -R 777 application/config && \
    chmod 644 .htaccess || true

# PHP configuration for production
RUN echo "upload_max_filesize = 100M" > /usr/local/etc/php/conf.d/uploads.ini && \
    echo "post_max_size = 100M" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "memory_limit = 256M" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "display_errors = On" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "log_errors = On" >> /usr/local/etc/php/conf.d/uploads.ini && \
    echo "error_log = /var/log/php_errors.log" >> /usr/local/etc/php/conf.d/uploads.ini && \
    touch /var/log/php_errors.log && \
    chmod 666 /var/log/php_errors.log

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2", "-D", "FOREGROUND"]
