if [ -f /opt/.easyweb ]; then
    exit
fi

apt update && apt install -y debian-keyring debian-archive-keyring apt-transport-https sudo caddy php php-fpm php-imagick php-gmp php-bcmath php-zip php-xml php-mbstring php-gd php-curl php-mysql mariadb-server mariadb-client dialog
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
apt install -y caddy
mysql_secure_installation

echo "# Custom config
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=100000
opcache.memory_consumption=512
opcache.save_comments=1
opcache.revalidate_freq=1" >> /etc/php/8.2/fpm/php.ini
service php8.2-fpm restart

touch /opt/.easyweb