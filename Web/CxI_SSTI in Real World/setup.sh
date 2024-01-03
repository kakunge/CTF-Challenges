#!/bin/bash
[ ! -d "/var/www/html/bootstrap" ] && \
    echo "Copying October CMS files..." && \
    cd /var/octobercms-source && \
    cp -r `ls -A` /var/www/html && \
    chmod -R 755 /var/www/html && \
    chown www-data:www-data -R /var/www/html

externalDatabaseExists=1
if ! [ -f /root/mysql-configured ]; then
    echo -e "[mysqld]\nskip-networking=0\nskip-bind-address\nbind-address=0.0.0.0\ndatadir=/var/lib/october-mysql" >> /etc/mysql/mariadb.conf.d/51-server-remote.cnf

    if ! [ -d /var/lib/october-mysql ]; then
        echo "Creating /var/lib/october-mysql..."
        mkdir /var/lib/october-mysql
    fi

    if [ -z "$(ls -A /var/lib/october-mysql | grep -v '^\.')" ]; then
        echo "Copying MySQL database files to /var/lib/october-mysql..."
        cp -RT /var/lib/mysql /var/lib/october-mysql
        externalDatabaseExists=0
    else
        echo "MySQL database files already exist in /var/lib/october-mysql."
    fi

    chown mysql:mysql -R /var/lib/october-mysql

    touch /root/mysql-configured
fi

service mariadb start

if ! [ -f /root/october-db-created ]; then
    if [ $externalDatabaseExists -ne 1 ]; then
        while ! mysqladmin ping --silent; do
            echo "Waiting for MySQL..."
            sleep 1
        done

        mysql -e "CREATE DATABASE IF NOT EXISTS octobercms"
        mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION"
        mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'root' WITH GRANT OPTION"
        
        sleep 1
        echo "Running October CMS migrations..."
        cd /var/www/html
        php artisan october:migrate
        php artisan theme:seed demo --root
        chmod -R 755 /var/www/html
        chown www-data:www-data -R /var/www/html
        mysql -proot octobercms < /init.sql
    fi

    touch /root/october-db-created
fi

service cron start
service apache2 start
tail -f /dev/null

