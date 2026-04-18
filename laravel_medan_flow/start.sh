#!/bin/bash
cd /var/www

cat > .env << EOF
APP_NAME=${APP_NAME}
APP_ENV=${APP_ENV}
APP_KEY=${APP_KEY}
APP_DEBUG=${APP_DEBUG}
APP_URL=${APP_URL}

LOG_CHANNEL=stderr

DB_CONNECTION=${DB_CONNECTION}
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_DATABASE=${DB_DATABASE}
DB_USERNAME=${DB_USERNAME}
DB_PASSWORD=${DB_PASSWORD}
EOF

php artisan config:cache
php artisan route:cache

php-fpm -D
sleep 3

nginx -g "daemon off;"
