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
    
    \$config = file_get_contents('/var/www/html/application/config/app-config-sample.php');
    \$config = str_replace('[base_url]', \$baseUrl, \$config);
    \$config = str_replace('[db_hostname]', \$dbHost, \$config);
    \$config = str_replace('[db_username]', \$dbUser, \$config);
    \$config = str_replace('[db_password]', \$dbPass, \$config);
    \$config = str_replace('[db_name]', \$dbName, \$config);
    \$config = str_replace('[encryption_key]', \$encKey, \$config);
    \$config = str_replace('[db_driver]', \$dbDriver, \$config);
    \$config = str_replace('[db_port]', \$dbPort, \$config);
    file_put_contents('/var/www/html/application/config/app-config.php', \$config);
    echo 'Runtime: Config file created from environment variables' . PHP_EOL;
"

# Run the original docker-php-entrypoint
exec docker-php-entrypoint "$@"
