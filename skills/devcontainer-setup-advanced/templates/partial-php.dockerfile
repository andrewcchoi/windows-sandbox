# === PHP LANGUAGE ADDITIONS ===
USER root

# Install PHP and required extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    php-cli \
    php-mbstring \
    php-xml \
    php-curl \
    php-zip \
    php-mysql \
    php-pgsql \
    php-sqlite3 \
    php-gd \
    php-opcache \
    libzip-dev \
    libpng-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Configure PHP
RUN mkdir -p /etc/php/*/cli/conf.d && \
    echo "memory_limit = 512M" >> /etc/php/*/cli/conf.d/99-custom.ini && \
    echo "upload_max_filesize = 64M" >> /etc/php/*/cli/conf.d/99-custom.ini && \
    echo "post_max_size = 64M" >> /etc/php/*/cli/conf.d/99-custom.ini

USER node

# === END PHP LANGUAGE ADDITIONS ===
