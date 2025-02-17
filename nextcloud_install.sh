//////////////////////////////////
// Настройка Ubuntu Server //
//////////////////////////////////

1. "Обновить и очистить пакеты"
sudo apt update
sudo apt upgrade
sudo apt autoremove

----------------------------------------------------------------
2. "Настроить hostname"
sudo vim /etc/hostname
  cloud
sudo vim /etc/hosts
    127.0.1.1 cloud

----------------------------------------------------------------
3. "Настроить timezone"
sudo timedatectl set-timezone Europe/Moscow

----------------------------------------------------------------
4. "Добавить пользователя"
adduser vol
usermod -aG sudo vol

----------------------------------------------------------------
10. "Настроить SSH по ключу"
# linux
sudo apt install openssh
# windows 
winget install openssh

# перейти в папку .ssh на локальной машине
cd ~/.ssh

# Сгенерировать ключ на локальной машине
ssh-keygen -t rsa -b 4096

# посмотреть созданные ключи
ls

# создание папки ssh на удаленном сервере
#ssh [remote_username]@[server_ip_address] mkdir -p .ssh
ssh vol@volgraft.ru mkdir -p .ssh

# скопировать публичный ключ на удаленный сервер
# scp .\[key.pub] [remote_username]@[server_ip_address]:/home/vol/.ssh/[key.pub]
scp C:\Users\admin\.ssh\key.pub vol@volgraft.ru:/home/vol/.ssh/key.pub
ssh-copy-id user@5.159.102.80
# подключится к удаленному серверу по ssh

# экспорт публичного ключа в uthorized_keys
cat ~/.ssh/key.pub >> ~/.ssh/authorized_keys

# отредактировать sshd_config
sudo vim /etc/ssh/sshd_config 
    Port 2822 # поменять порт SSH
    UsePAM yes
    PasswordAuthentication no
    PermitRootLogin no

# перезагрузить sshd сервис
sudo systemctl restart sshd

# Включить ssh агент
Start-Service ssh-agent 
    Get-Service ssh-agent
    Get-Service ssh-agent | Select StartType
    Get-Service -Name ssh-agent | Set-Service -StartupType Manual

# Добавить ключ в SSH агент
# ssh-add <path to new private key file>
ssh-add c:/Users/admin/.ssh/key

sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon --show
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
sudo sysctl vm.vfs_cache_pressure=50

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// 002. Установка и настройка NextCloud (установка сервера, базы данных; монтирование директории data) //
/////////////////////////////////////////////////////////////////////////////////////////////////////////

1. "Установка и настройка базы данных"
sudo apt install mariadb-server
systemctl status mariadb

----------------------------------------------------------------
2. "Настройки безопасности MariaDB"
sudo mysql_secure_installation

Enter current password for root (enter for none): none

Switch to unix_socket authentication [Y/n] : n

Change the root password? [Y/n]: y

Remove anonymous users? [Y/n]: y

Disallow root login remotely? [Y/n]: y

Remove test database and access to it? [Y/n]: y

Reload privilege tables now? [Y/n]: y

----------------------------------------------------------------
3. "Создание базы nextcloud"
sudo mariadb
  CREATE DATABASE nextcloud;
  SHOW DATABASES;
  GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'localhost' IDENTIFIED BY 'mypassword';
  FLUSH PRIVILEGES;
  exit

# сменить пароль юзера maiadb (если забыл)
  # ALTER USER 'user'@'localhost' IDENTIFIED BY 'new_password'; сменить пароль юзера maiadb
  # FLUSH PRIVILEGES;
  # exit

----------------------------------------------------------------
4. "Установка WEB сервера"
sudo apt install php php-apcu php-bcmath php-cli php-common php-curl php-gd php-gmp php-imagick php-intl php-mbstring php-mysql php-zip php-xml
systemctl status apache2 # apache2 должен установится как зависимость вместе с предыдущей командой

----------------------------------------------------------------
5."Enable PHP extensions"
sudo phpenmod bcmath gmp imagick intl

----------------------------------------------------------------
6. "Скачать дистрибутив Nextcloud"
https://nextcloud.com/
wget https://download.nextcloud.com/server/releases/latest.zip

----------------------------------------------------------------
7. "Распаковать и установить Nextcloud"
sudo apt install unzip
unzip latest.zip
sudo mv nextcloud /var/www/
rm latest.zip

----------------------------------------------------------------
8. "Сменить владельца /var/www/nextcloud/"
sudo chown -R www-data:www-data /var/www/nextcloud/

----------------------------------------------------------------
9. "apache2 disable default site"
sudo a2dissite 000-default.conf

----------------------------------------------------------------
10. "Настроить сайт nextcloud"
sudo vim /etc/apache2/sites-available/nextcloud.conf

<VirtualHost *:80>
    DocumentRoot "/var/www/nextcloud"
    ServerName cloud

    <Directory "/var/www/nextcloud/">
        Options MultiViews FollowSymlinks
        AllowOverride All
        Order allow,deny
        Allow from all
   </Directory>

   TransferLog /var/log/apache2/nextcloud.log
   ErrorLog /var/log/apache2/nextcloud.log

</VirtualHost>

----------------------------------------------------------------
11. "apache2 enable nextcloud site"
sudo a2ensite nextcloud.conf

----------------------------------------------------------------
12. "Конфигурирование appache сервера"
# sudo vim /etc/php/8.1/apache2/php.ini

# провести проверку текущих настроек через cat
cat /etc/php/8.1/apache2/php.ini | grep 'memory_limit = '
cat /etc/php/8.1/apache2/php.ini | grep 'upload_max_filesize ='
cat /etc/php/8.1/apache2/php.ini | grep 'max_execution_time ='
cat /etc/php/8.1/apache2/php.ini | grep 'post_max_size ='
cat /etc/php/8.1/apache2/php.ini | grep 'date.timezone ='
cat /etc/php/8.1/apache2/php.ini | grep 'opcache.enable='
cat /etc/php/8.1/apache2/php.ini | grep 'opcache.interned_strings_buffer='
cat /etc/php/8.1/apache2/php.ini | grep 'opcache.max_accelerated_files='
cat /etc/php/8.1/apache2/php.ini | grep 'opcache.memory_consumption='
cat /etc/php/8.1/apache2/php.ini | grep 'opcache.save_comments='
cat /etc/php/8.1/apache2/php.ini | grep 'opcache.revalidate_freq='

# заменить требуемые строки настроек
sudo sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/8.1/apache2/php.ini
sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 200M/g' /etc/php/8.1/apache2/php.ini
sudo sed -i 's/max_execution_time = 30/max_execution_time = 360/g' /etc/php/8.1/apache2/php.ini
sudo sed -i 's/post_max_size = 8M/post_max_size = 200M/g' /etc/php/8.1/apache2/php.ini
sudo sed -i 's/;date.timezone =/date.timezone = Europe\/Moscow/g' /etc/php/8.1/apache2/php.ini
sudo sed -i 's/;opcache.enable=1/opcache.enable=1/g' /etc/php/8.1/apache2/php.ini
sudo sed -i 's/;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=8/g' /etc/php/8.1/apache2/php.ini
sudo sed -i 's/;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=10000/g' /etc/php/8.1/apache2/php.ini
sudo sed -i 's/;opcache.memory_consumption=128/opcache.memory_consumption=128/g' /etc/php/8.1/apache2/php.ini
sudo sed -i 's/;opcache.save_comments=1/opcache.save_comments=1/g' /etc/php/8.1/apache2/php.ini
sudo sed -i 's/;opcache.revalidate_freq=2/opcache.revalidate_freq=1/g' /etc/php/8.1/apache2/php.ini

# провести проверку через cat снова, результат ниже:
memory_limit = 512M
upload_max_filesize = 200M
max_execution_time = 360
post_max_size = 200M
date.timezone = Europe/Moscow
opcache.enable=1
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=10000
opcache.memory_consumption=128
opcache.save_comments=1
opcache.revalidate_freq=1

----------------------------------------------------------------
13. "Перепроверить модификаторы appache и перезагрузить appache"
sudo a2enmod dir env headers mime rewrite ssl
sudo systemctl restart apache2

----------------------------------------------------------------
14. "Перейти на сайт и завершить установку nextcloud"

/////////////////////////////////////////////
// 003. Дополнительные настройки и сервисы //
/////////////////////////////////////////////

1. "Дополнительный софт"
sudo apt install libapache2-mod-php imagemagick ffmpeg php-bz2 php-redis redis-server unzip redis-server php-redis cron ncdu lnav net-tools iotop htop

----------------------------------------------------------------
2. "Добавить в 'trusted_domains' все адреса, к которым будет осуществляться подключение"
sudo vim /var/www/nextcloud/config/config.php 

'trusted_domains' =>
array (
    0 => 'cloud.volgraft.ru',
),

----------------------------------------------------------------
3. "Дополнительные настройки в nextcloud/config/config.php"
sudo vim /var/www/nextcloud/config/config.php
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'default_phone_region' => 'RU',
  'simpleSignUpLink.shown' => false,
  'config_is_read_only' => true,
  'maintenance' => false,

----------------------------------------------------------------
4. "Убрать ошибку Image Magick error"
sudo apt install libmagickcore-6.q16-6-extra

----------------------------------------------------------------
5. "Настроить certbot"
https://certbot.eff.org/instructions

----------------------------------------------------------------
6. "Enabling Strict Transport Security"
sudo vim /etc/apache2/sites-available/nextcloud-le-ssl.conf

<IfModule mod_ssl.c>
<VirtualHost *:443>
  ............
  Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains" # добавить эту строку
  ............
</VirtualHost>
</IfModule>

----------------------------------------------------------------
7. "Reditect to 443"
sudo vim /etc/apache2/sites-available/nc-redir.conf

<VirtualHost *:80>
   ServerName nc.domain.org

   RewriteEngine On
   RewriteCond %{HTTPS} off
   RewriteRule ^(.*)$ https://%{HTTP_HOST}$1 [R=301,L]
</VirtualHost>

sudo systemctl restart apache2

----------------------------------------------------------------
8. "Настроить cron"

# Configuration settings > Basic settings > Enable Cron

sudo apt install cron
sudo systemctl enable cron

sudo crontab -e
  */5  *  *  *  * php -f /var/www/nextcloud/cron.php  # вставить в конце, не забыть про перенос на новую строку в конце
sudo crontab -l

----------------------------------------------------------------
9. "Настроить redis"
ps ax | grep redis
sudo apt install redis-server php-redis
ps ax | grep redis
sudo usermod -a -G redis www-data
sudo systemctl restart apache2

sudo vim /etc/redis/redis.conf
  unixsocket /var/run/redis/redis-server.sock
  unixsocketperm 770
  port 0

sudo systemctl restart redis

sudo vim /var/www/nextcloud/config/config.php
# удалить строку 
  'memcache.local' => '\\OC\\Memcache\\APCu',
# и добавить строки
  'filelocking.enabled' => true,
  'memcache.distributed' => '\\OC\\Memcache\\Redis',
  'memcache.local' => '\\OC\\Memcache\\Redis',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' => 
  array (
        'host' => '/var/run/redis/redis-server.sock',
        'port' => 0,
  ),

sudo -u www-data php /var/www/nextcloud/occ background:cron

----------------------------------------------------------------
10. "Настроить fail2ban"
sudo apt install fail2ban

sudo cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

sudo vim /etc/fail2ban/jail.local
  ignoreip = 127.0.0.1/8 ::1

# Create a file in /etc/fail2ban/filter.d named nextcloud.conf with the following contents:
sudo vim /etc/fail2ban/filter.d/nextcloud.conf

[Definition]
_groupsre = (?:(?:,?\s*"\w+":(?:"[^"]+"|\w+))*)
failregex = ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Login failed:
            ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Trusted domain error.
datepattern = ,?\s*"time"\s*:\s*"%%Y-%%m-%%d[T ]%%H:%%M:%%S(%%z)?"

# Create a file in /etc/fail2ban/jail.d named nextcloud.local with the following contents:
sudo vim /etc/fail2ban/jail.d/nextcloud.local

[nextcloud]
backend = auto
enabled = true
port = 80,443
protocol = tcp
filter = nextcloud
maxretry = 3
bantime = 86400
findtime = 3600
logpath = /var/log/nextcloud.log

# config sshd
sudo vim /etc/fail2ban/jail.d/sshd.local

[sshd]
backend = systemd
enabled = true
port = ssh
protocol = tcp
filter = sshd
maxretry = 1
bantime = 1d
findtime = 60m
logpath = %(sshd_log)s

# создать файл логов
sudo touch /var/log/nextcloud.log 
sudo chown www-data:www-data /var/log/nextcloud.log
sudo chmod 660 /var/log/nextcloud.log

sudo systemctl enable fail2ban
sudo systemctl restart fail2ban
sudo systemctl status fail2ban

----------------------------------------------------------------
11. "ufw"
sudo apt-get install ufw 
sudo vim /etc/default/ufw 
  IPV6=yes
  
sudo ufw default deny

sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443

sudo ufw enable

----------------------------------------------------------------
12. "Логи"
sudo vim /var/www/nextcloud/config/config.php
  # в конец
  'log_type' => "file",
  'logfile' => '/var/log/nextcloud.log',
  'loglevel' => 1,
  'logdateformat' => "F d, Y H:i:s",

sudo touch /var/log/nextcloud.log
sudo chown -R root:www-data /var/log/nextcloud.log

sudo systemctl restart apache2

# lnav - просмотр логов
sudo tail -n 100 /var/log/nextcloud.log
sudo tail -n 100 /var/log/apache2/nextcloud.log

----------------------------------------------------------------
13. "Удалить index.php из URL"
sudo vim /var/www/nextcloud/config/config.php
  'htaccess.RewriteBase' => '/',

sudo php /var/www/nextcloud/occ maintenance:update:htaccess

----------------------------------------------------------------
14. "Настроить права доступа к nextcloud/config/config.php"
sudo chmod 660 /var/www/nextcloud/config/config.php
sudo chown root:www-data /var/www/nextcloud/config/config.php

//////////////////////////////
// 004. Установка Collabora //
//////////////////////////////

0. Создать DNS запись
Cоздать A запись collabora.volgraft.ru = IP вашего nextcloud

----------------------------------------------------------------
1. Установка
В web интерфейсе установить приложение "Nextcloud Office"

----------------------------------------------------------------
2. Импорт ключа официального репозитория
sudo apt install gnupg
cd /usr/share/keyrings
sudo wget https://collaboraoffice.com/downloads/gpg/collaboraonline-release-keyring.gpg

----------------------------------------------------------------
3. Добавить репозиторий
sudo vim /etc/apt/sources.list.d/collaboraonline.sources

Types: deb
URIs: https://www.collaboraoffice.com/repos/CollaboraOnline/CODE-ubuntu2204
Suites: ./
Signed-By: /usr/share/keyrings/collaboraonline-release-keyring.gpg

----------------------------------------------------------------
4. Установить необходимые пакеты
sudo apt update && sudo apt install coolwsd code-brand hunspell collaboraoffice*

----------------------------------------------------------------
5. Настройка Apache для Collabora

sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/collabora.conf

sudo vim /etc/apache2/sites-available/collabora.conf
- настроить ServerName (collabora.volgraft.ru)
- удалить ServerAdmin и DocumentRoot

sudo a2ensite collabora && sudo systemctl reload apache2

----------------------------------------------------------------
6. Получить SSL сертификат с помощью certbot 
sudo certbot --apache

----------------------------------------------------------------
7. Включить модули apache
sudo a2enmod proxy proxy_wstunnel proxy_http proxy_connect

----------------------------------------------------------------
8. Настроить SSL конфиг Collabora на локальную работу

sudo vim /etc/apache2/sites-enabled/collabora-le-ssl.conf

        Options -Indexes

        AllowEncodedSlashes NoDecode
        ProxyPreserveHost On


        # static html, js, images, etc. served from coolwsd
        # browser is the client part of Collabora Online
        ProxyPass           /browser http://127.0.0.1:9980/browser retry=0
        ProxyPassReverse    /browser http://127.0.0.1:9980/browser


        # WOPI discovery URL
        ProxyPass           /hosting/discovery http://127.0.0.1:9980/hosting/discovery retry=0
        ProxyPassReverse    /hosting/discovery http://127.0.0.1:9980/hosting/discovery


        # Capabilities
        ProxyPass           /hosting/capabilities http://127.0.0.1:9980/hosting/capabilities retry=0
        ProxyPassReverse    /hosting/capabilities http://127.0.0.1:9980/hosting/capabilities


        # Main websocket
        ProxyPassMatch      "/cool/(.*)/ws$"      ws://127.0.0.1:9980/cool/$1/ws nocanon


        # Admin Console websocket
        ProxyPass           /cool/adminws ws://127.0.0.1:9980/cool/adminws


        # Download as, Fullscreen presentation and Image upload operations
        ProxyPass           /cool http://127.0.0.1:9980/cool
        ProxyPassReverse    /cool http://127.0.0.1:9980/cool
        # Compatibility with integrations that use the /lool/convert-to endpoint
        ProxyPass           /lool http://127.0.0.1:9980/cool
        ProxyPassReverse    /lool http://127.0.0.1:9980/cool


        ErrorLog /var/log/apache2/collabora-error.log
        CustomLog /var/log/apache2/collabora-access.log combined

----------------------------------------------------------------
9. Настройка файлов логов
sudo touch /var/log/apache2/collabora-error.log
sudo touch /var/log/apache2/collabora-access.log

sudo chown root:cool /var/log/apache2/collabora-error.log
sudo chown root:cool /var/log/apache2/collabora-access.log

----------------------------------------------------------------
10. Перезапустить apache
sudo systemctl restart apache2

----------------------------------------------------------------
11. Настроить конфиг Collabora
sudo vim /etc/coolwsd/coolwsd.xml
  de_DE en_GB en_US es_ES fr_FR it nl pt_BR pt_PT ru 
  > 
  ru en_US


sudo coolconfig set ssl.enable false
sudo coolconfig set ssl.termination true

----------------------------------------------------------------
12. Перезапустить Collabora
sudo systemctl restart coolwsd
sudo systemctl status coolwsd

----------------------------------------------------------------
13. Включить Collabora в Nextcloud
В WEB интерфейсе в настройках найти опцию Office и подключится к настроенному серверу https://collabora.volgraft.ru
Заполнить опцию Allow list for WOPI requests , IP адресом collabora сервера

Troubleshoot
# https://sdk.collaboraonline.com/docs/installation/Collabora_Online_Troubleshooting_Guide.html
journalctl -e -u coolwsd | lnav
journalctl -r -u coolwsd | lnav

///////////////
// ИСТОЧНИКИ //
///////////////

- Установка и настройка Nextcloud
# https://docs.nextcloud.com/server/latest/admin_manual/configuration_server
# https://www.youtube.com/@LearnLinuxTV/videos
# https://www.youtube.com/@NerdOnTheStreet/videos

- Установка Collabora
# Installation example on Ubuntu https://docs.nextcloud.com/server/latest/admin_manual/office/example-ubuntu.html
# Reverse proxy https://docs.nextcloud.com/server/latest/admin_manual/office/proxy.html
# Proxy settings https://sdk.collaboraonline.com/docs/installation/Proxy_settings.html
# Setting up and configuring https://www.collaboraoffice.com/code/linux-packages/
# Video https://nerdonthestreet.com/wiki?find=Install+Nextcloud+21%2C+Collabora%2C+and+HPB+on+Debian+10



