#!/bin/bash

# Script for installing WordPress.
# Compatible for Debian/Ubuntu based distro.
# Recommended for fresh install Ubuntu server.

# STEP 0: initialization
printf "Welcome to wp-install.sh script!\n"
printf "Please note, this script is intended for fresh install.\n"
printf "No checking packages and ready to install.\n"
printf "Please consider to check this script code to get more information.\n\n"

while true; do
    read -p "Are you ready to continue? (y/n) " yn
    case $yn in
    [Yy]*)
        break
        ;;
    [Nn]*) exit ;;
    *) printf "Please answer 'Y/y' or 'N/n'.\n" ;;
    esac
done

# STEP 1: check root user
if ! [ $(id -u) = 0 ]; then
    printf "Not in root!\n"
    exit 1
fi

# STEP 2: installing apache2, mysql server, and php package
printf "Installing apache2, mysql-server, and required php module.\n"
apt install -y apache2 ghostscript libapache2-mod-php mysql-server php php-bcmath php-curl php-imagick php-intl php-gd php-json php-mbstring php-mysql php-xml php-zip

# STEP 3: downloading latest version of WordPress in tar.gz file and configure
printf "Configuring WordPress file.\n"
cd /var/www/html

FILE=latest.tar.gz
if test -f "$FILE"; then
    printf "$FILE exists, decompress instead of redownload\n."
else
    wget https://wordpress.org/latest.tar.gz
fi

tar zxvf latest.tar.gz

read -p "Input directory name for WordPress (e.g. yoursite.com): " dirname
mv /var/www/html/wordpress /var/www/html/$dirname

chown -R www-data:www-data /var/www/html/$dirname

# STEP 4: configuring apache2 config
read -p "Input config name for apache2 (e.g. yoursite.com.conf): " confname
{
    printf "<VirtualHost *:80>\n"
    printf "  DocumentRoot /var/www/html/$dirname\n"
    printf "  <Directory /var/www/html/$dirname>\n"
    printf "      Options FollowSymLinks\n"
    printf "      AllowOverride Limit Options FileInfo\n"
    printf "      DirectoryIndex index.php\n"
    printf "      Require all granted\n"
    printf "  </Directory>\n"
    printf "  <Directory /var/www/html/$dirname/wp-content>\n"
    printf "      Options FollowSymLinks\n"
    printf "      Require all granted\n"
    printf "      AllowOverride All\n"
    printf "  </Directory>\n"
    printf "</VirtualHost>\n"
} >>/etc/apache2/sites-available/$confname

rm /etc/apache2/sites-enabled/*

a2ensite $confname
a2enmod rewrite

systemctl restart apache2.service

# STEP 5: creating database and the setting up
read -p "Input database name for WordPress (e.g. yoursitecom): " dbname
mysql -u root -e "CREATE DATABASE $dbname;GRANT ALL PRIVILEGES ON $dbname.* TO root@localhost;FLUSH PRIVILEGES;"

# STEP 6: finalization
printf "
    Visit IP server, then this is database connection details.
    Database Name   : $dbname
    Username        : root
    Password        : (leave it blank)
    Database Host   : localhost
    Table Prefix    : (default 'wp_' or change)\n
"

printf "Reach to finalization. Please check your site.\n"
printf "Exiting tool.\n"

exit 0
