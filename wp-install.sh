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
wget https://wordpress.org/latest.tar.gz
sudo -u www-data: tar zxvf latest.tar.gz

read -p "Input directory name for WordPress (e.g. yoursite.com): " dirname
sudo -u www-data mv /var/www/html/wordpress /var/www/html/$dirname

# STEP 4: configuring apache2 config
read -p "Input config name for apache2 (e.g. yoursite.com.conf): " confname
{
    echo "<VirtualHost *:80>"
    echo "  DocumentRoot /var/www/html/$dirname"
    echo "  <Directory /var/www/html/$dirname>"
    echo "      Options FollowSymLinks"
    echo "      AllowOverride Limit Options FileInfo"
    echo "      DirectoryIndex index.php"
    echo "      Require all granted"
    echo "  </Directory>"
    echo "  <Directory /var/www/html/$dirname/wp-content>"
    echo "      Options FollowSymLinks"
    echo "      Require all granted"
    echo "      AllowOverride All"
    echo "  </Directory>"
    echo "</VirtualHost>"
} >> /etc/apache2/sites-available/$confname

a2dissite *
a2ensite $confname
a2enmod rewrite

systemctl restart apache2.service

# STEP 5: creating database and the setting up
read -p "Input database name for WordPress (e.g. yoursitecom): " dbname
mysql --user=root << EOF
CREATE DATABASE $dbname;
GRANT ALL PRIVILEGES ON $dbname.* TO root@localhost;
FLUSH PRIVILEGES;
EOF

# STEP 6: finalization
printf "Reach to finalization. Please check your site.\n"
printf "Exiting tool."

exit 0;
