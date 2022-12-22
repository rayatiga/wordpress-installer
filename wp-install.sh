#!/bin/bash

# Script for installing WordPress.
# Compatible for Debian/Ubuntu based distro.
# Recommended for fresh install Ubuntu server.

# STEP -1: removing rest of file (especially for testing)
if ! [ $(id -u) = 0 ]; then
    printf "Not in root!\n"
    exit 1
fi

while true; do
    read -p "Testing/under development? (y/n): " yn
    case $yn in
    [Yy]*)
        printf "Deleting WordPress directory and custom apache2 configuration..."
        find /var/www/html/ -type f -not \( -name 'latest.tar.gz' -or -name 'index.html' \) -delete
        find /etc/apache2/sites-available/ -type f -not \( -name '000-default.conf' \) -delete
        sleep 2
        printf "Deleted."
        sleep 1
        break
        ;;
    [Nn]*) exit ;;
    *) printf "Please answer 'Y/y' or 'N/n'.\n" ;;
    esac
done
clear

# STEP 0: initialization
printf "\nWelcome to wp-install.sh script!\n"
printf "Please note, this script is intended for fresh install.\n"
printf "No checking packages and ready to install.\n"
printf "Please consider to check this script code to get more information.\n\n"

while true; do
    read -p "Are you ready to continue? (y/n): " yn
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
printf "\nInstalling apache2, mysql-server, and required php module...\n"
apt install -y apache2 ghostscript libapache2-mod-php mysql-server php php-bcmath php-curl php-imagick php-intl php-gd php-json php-mbstring php-mysql php-xml php-zip >/dev/null 2>&1
printf "Installed.\n"

# STEP 3: downloading latest version of WordPress in tar.gz file and configure
printf "\nConfiguring WordPress file...\n"
cd /var/www/html

FILE=latest.tar.gz
if test -f "$FILE"; then
    printf "File $FILE exists, decompress instead of redownload.\n"
    sleep 3
else
    printf "Downloading latest version of Wordpress...\n"
    wget https://wordpress.org/latest.tar.gz >/dev/null 2>&1
    printf "Downloaded.\n"
fi

printf "Decompressing $FILE...\n"
tar zxvf latest.tar.gz >/dev/null 2>&1
printf "Decompressed.\n"

printf "\n"
read -p "Input directory name for WordPress (e.g. yoursite.com): " dirname
mv /var/www/html/wordpress /var/www/html/$dirname

chown -R www-data:www-data /var/www/html/$dirname

# STEP 4: configuring apache2 config
printf "\n"
read -p "Input config name for apache2 (e.g. yoursite.com without '.conf'): " confname
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
} >>/etc/apache2/sites-available/$confname.conf

printf "Configuring apache2...\n"
rm /etc/apache2/sites-enabled/* >/dev/null 2>&1

a2ensite $confname >/dev/null 2>&1
a2enmod rewrite >/dev/null 2>&1

systemctl restart apache2.service >/dev/null 2>&1
printf "Configured.\n"

# STEP 5: creating database and the setting up
printf "\n"
read -p "Input database name for WordPress (e.g. yoursitecom): " dbname

while true; do
    read -p "Do you have mysql user root configured/secured by password? (y/n): " yn
    case $yn in
    [Yy]*)
        printf "Please enter correct password, there is no checking/validation!\n"
        while true; do
            read -p "Enter your root password: " dbpass1
            read -p "Enter your confirmation root password: " dbpass2
            if [ "$dbpass1" = "$dbpass2" ]; then
                dbpass=$dbpass2
                break
            else
                printf "Password $dbpass1 and $dbpass2 is not matched!\n"
            fi
        done
        break
        ;;
    [Nn]*)
        dbuser=root
        printf "Configure database for user $dbuser.\n"
        read -p "Please enter database $dbuser password: " dbpass
        mysql -u root -p$dbpass -e "ALTER USER $dbuser@localhost IDENTIFIED WITH caching_sha2_password BY '$dbpass';" >/dev/null 2>&1
        break
        ;;
    *) printf "Please answer 'Y/y' or 'N/n'.\n" ;;
    esac
done

while true; do
    read -p "Are you want to create database specific user? (y/n): " yn
    case $yn in
    [Yy]*)
        read -p "Please enter database username: " dbuser
        read -p "Please enter database user password: " dbpass
        mysql -u root -p$dbpass "CREATE USER $dbuser@localhost IDENTIFIED BY '$dbpass';" >/dev/null 2>&1
        break
        ;;
    [Nn]*)
        dbuser=root
        break
        ;;
    *) printf "Please answer 'Y/y' or 'N/n'.\n" ;;
    esac
done
mysql -u root -p$dbpass -e "CREATE DATABASE $dbname;GRANT ALL PRIVILEGES ON $dbname.* TO $dbuser@localhost;FLUSH PRIVILEGES;" >/dev/null 2>&1

# STEP 6: finalization
printf "
    Visit IP server, then this is database connection details.
    Database Name   : $dbname
    Username        : $dbuser
    Password        : $dbpass
    Database Host   : localhost
    Table Prefix    : (default 'wp_' or change)\n

    Your complete information output from this program.
    File Downloaded : /var/www/html/$FILE
    Document Root   : /var/www/html/$dirname
    Configuration   : /etc/apache2/sites-available/$confname.conf
    For databse see above.
"

printf "\nReach to finalization. Please check your site.\n"
printf "Exiting tool.\n"

exit 0
