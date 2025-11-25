#!/bin/bash
set -e

# Generate app-config.php from environment variables at runtime
php -r "
    \$baseUrl = getenv('APP_BASE_URL') ?: 'http://localhost/';
    \$dbDriver = getenv('APP_DB_DRIVER') ?: 'pgsql';
    \$dbHost = getenv('APP_DB_HOSTNAME') ?: 'localhost';
    \$dbPort = getenv('APP_DB_PORT') ?: '5432';
    \$dbUser = getenv('APP_DB_USERNAME') ?: 'root';
    \$dbPass = getenv('APP_DB_PASSWORD') ?: '';
    \$dbName = getenv('APP_DB_NAME') ?: 'perfex_crm';
    \$encKey = getenv('APP_ENC_KEY') ?: 'default_encryption_key_change_in_production';
    
    error_log('=== RENDER CONFIG GENERATION ===');
    error_log('Base URL: ' . \$baseUrl);
    error_log('DB Driver: ' . \$dbDriver);
    error_log('DB Host: ' . \$dbHost);
    error_log('DB Port: ' . \$dbPort);
    error_log('DB Name: ' . \$dbName);
    error_log('DB User: ' . \$dbUser);
    
    \$config = file_get_contents('/var/www/html/application/config/app-config-sample.php');
    \$config = str_replace('[base_url]', \$baseUrl, \$config);
    \$config = str_replace('[db_hostname]', \$dbHost, \$config);
    \$config = str_replace('[db_port]', \$dbPort, \$config);
    \$config = str_replace('[db_username]', \$dbUser, \$config);
    \$config = str_replace('[db_password]', \$dbPass, \$config);
    \$config = str_replace('[db_name]', \$dbName, \$config);
    \$config = str_replace('[encryption_key]', \$encKey, \$config);
    \$config = str_replace('[db_driver]', \$dbDriver, \$config);
    file_put_contents('/var/www/html/application/config/app-config.php', \$config);
    error_log('Config file created successfully');
    error_log('=== CONFIG GENERATION COMPLETE ===');
" 2>&1 | tee -a /var/log/php_errors.log

echo 'Waiting for database...'
sleep 2

# Run the original docker-php-entrypoint
exec docker-php-entrypoint \"$@\"
" 2>&1 | tee -a /var/log/php_errors.log
