#!/bin/bash

# Script for installing WordPress.
# Compatible for Debian/Ubuntu based distro.
# Recommended for fresh install Ubuntu server.

# STEP -3: fisrt run
if ! [ $(id -u) = 0 ]; then
    printf "Please run as root!\n"
    exit 1
fi

printf "\nWordPress Installer Script by https://github.com/bydzen/. Well managed.\n"
printf "Any issue? go to https://github.com/rayatiga/wordpress-installer/issues/. Create new issue.\n"
printf "Visit more on https://github.com/rayatiga/wordpress-installer/. GitHub repository.\n"

# STEP -2: removing rest of file (especially for testing)
while true; do
    printf "\nThis script provide for development too. Therefore feature named 'CLEAN' will be introduce first.\nCLEAN will delete apache2 file as detail below.
    Root Directory  : /var/www/html/* (except latest.tar.gz and index.html)
    Config Directory: /etc/apache2/sites-available/* (except 000-default.conf)\n"
    read -p "WARNING! Run CLEAN for erase previously? (y/n): " yn
    case $yn in
    [Yy]*)
        printf "\nDeleting WordPress directory and custom apache2 configuration...\n"
        sleep 1
        find /var/www/html/ -mindepth 1 -name 'latest.tar.gz' -or -name 'index.html' -prune -o -exec rm -rf {} \;
        find /etc/apache2/sites-available/ -type f -not \( -name '000-default.conf' \) -delete
        printf "Deleted. ✓\n"
        sleep 1
        break
        ;;
    [Nn]*)
        break
        ;;
    *) printf "Please answer 'Y/y' or 'N/n'.\n" ;;
    esac
done

# STEP -1: giving change information
printf "\nThis script will modified file as detail below.\n"
printf "1. Directory /var/www/html/\n"
printf "2. Directory /etc/apache2/sites-available/\n"
printf "3. Directory /etc/apache2/sites-enabled/\n"

printf "\nThis script can also make changes to the detail below.\n"
printf "1. Altering user root databse\n"
printf "2. Creating new database\n"
printf "3. Creating new database user\n"
printf "4. Creating new database password\n\n"

while true; do
    read -p "Accept the ability above? (y/n): " yn
    case $yn in
    [Yy]*)
        break
        ;;
    [Nn]*)
        printf "\nExiting tool.\n"
        exit
        ;;
    *) printf "Please answer 'Y/y' or 'N/n'.\n" ;;
    esac
done

# STEP 0: initialization
printf "\nWelcome to wp-install.sh script!\n"
printf "Please note, this script is intended for WordPress fresh install.\n"
printf "No checking packages, no sub-directory/domain, just root for one WordPress config.\n"
printf "Please consider to check this script code to get more information.\n\n"

while true; do
    read -p "Are you sure to continue? (y/n): " yn
    case $yn in
    [Yy]*)
        break
        ;;
    [Nn]*)
        printf "\nExiting tool.\n"
        exit
        ;;
    *) printf "Please answer 'Y/y' or 'N/n'.\n" ;;
    esac
done

# STEP 1: check root user (again)
if ! [ $(id -u) = 0 ]; then
    printf "Please run as root!\n"
    exit 1
fi

# STEP 2: installing apache2, mysql server, and php package
printf "\nInstalling apache2, mysql-server, and required php module...\n"
sleep 1
apt install -y apache2 ghostscript libapache2-mod-php mysql-server php php-bcmath php-curl php-imagick php-intl php-gd php-json php-mbstring php-mysql php-xml php-zip >/dev/null 2>&1
printf "Installed. ✓\n"
sleep 1

# STEP 3: downloading latest version of WordPress in tar.gz file and configure
printf "\nConfiguring WordPress file...\n"
sleep 1
cd /var/www/html

FILE=latest.tar.gz
if test -f "$FILE"; then
    printf "File $FILE exists, decompress instead of redownload. ✓\n"
    sleep 1
else
    printf "Downloading latest version of WordPress...\n"
    sleep 1
    wget https://wordpress.org/latest.tar.gz >/dev/null 2>&1
    printf "Downloaded. ✓\n"
    sleep 1
fi

printf "\nDecompressing $FILE...\n"
sleep 1
tar zxvf latest.tar.gz >/dev/null 2>&1
printf "Decompressed. ✓\n\n"
sleep 1

read -p "Input directory name for WordPress (e.g. yoursite.com): " dirname
mv /var/www/html/wordpress /var/www/html/$dirname

chown -R www-data:www-data /var/www/html/$dirname

# STEP 4: configuring apache2 config
printf "\n"
read -p "Input config name for apache2 (e.g. yoursite.com without '.conf'): " confname
{
    # FALLBACK: if config below commenting line not properly work for your WordPress webstie.
    # printf "<VirtualHost *:80>\n"
    # printf "  DocumentRoot /var/www/html/\n"
    # printf "  <Directory /var/www/html/*>\n"
    # printf "      AllowOverride all\n"
    # printf "  </Directory>\n"
    # printf "</VirtualHost>\n"
    # Below is active config.
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

printf "\nConfiguring apache2...\n"
sleep 1
rm /etc/apache2/sites-enabled/* >/dev/null 2>&1

a2ensite $confname >/dev/null 2>&1
a2enmod rewrite >/dev/null 2>&1

systemctl restart apache2.service >/dev/null 2>&1
printf "Configured. ✓\n\n"
sleep 1

# STEP 5: creating database and the setting up
read -p "Input database name for WordPress (e.g. db_yoursitecom): " dbname

while true; do
    printf "\n"
    read -p "Do you have mysql user root configured/secured by password? (y/n): " yn
    case $yn in
    [Yy]*)
        dbuser=root
        while true; do
            printf "\nPlease enter correct password, there is no checking/validation!\n"
            read -p "Enter your $dbuser password: " dbpass1
            read -p "Enter your confirmation $dbuser password: " dbpass2
            if [ "$dbpass1" = "$dbpass2" ]; then
                dbpass=$dbpass2
                dbpassroot=$dbpass2
                break
            else
                printf "Password $dbpass1 and $dbpass2 for user $dbuser is not match!\n"
            fi
        done
        break
        ;;
    [Nn]*)
        dbuser=root
        printf "\nConfigure database for user $dbuser.\n"
        read -p "Enter your new $dbuser password: " dbpassroot
        mysql -u root -p$dbpassroot -e "ALTER USER $dbuser@localhost IDENTIFIED WITH caching_sha2_password BY '$dbpassroot';" >/dev/null 2>&1
        dbpass=$dbpassroot
        break
        ;;
    *) printf "Please answer 'Y/y' or 'N/n'.\n" ;;
    esac
done

printf "\n"
while true; do
    read -p "Are you want to create database specific user? (y/n): " yn
    case $yn in
    [Yy]*)
        read -p "Please enter database username: " dbuser
        read -p "Please enter database user password: " dbpass
        mysql -u root -p$dbpassroot -e "CREATE USER $dbuser@localhost IDENTIFIED BY '$dbpass';" >/dev/null 2>&1
        break
        ;;
    [Nn]*)
        sleep 1
        printf "Using $dbuser for handling WordPress database. ✓\n"
        sleep 1
        break
        ;;
    *) printf "Please answer 'Y/y' or 'N/n'.\n" ;;
    esac
done
mysql -u root -p$dbpassroot -e "CREATE DATABASE $dbname;GRANT ALL PRIVILEGES ON $dbname.* TO $dbuser@localhost;FLUSH PRIVILEGES;" >/dev/null 2>&1

# STEP 6: finalization
sleep 1
printf "
    Visit IP server, then this is database connection detail.
    Database Name   : $dbname
    Username        : $dbuser
    Password        : $dbpass
    Database Host   : localhost
    Table Prefix    : (default 'wp_' or change)

    Your complete information output from this program.
    File Downloaded : /var/www/html/$FILE
    Document Root   : /var/www/html/$dirname
    Configuration   : /etc/apache2/sites-available/$confname.conf
    For databse see above.
"
sleep 1

printf "\nReach to finalization. Thank you!\n"
printf "Please check your site.\n"
printf "Exiting tool.\n"

exit 0
