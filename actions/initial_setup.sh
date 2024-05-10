if [ -f /opt/.easyweb ]; then
    exit
fi


# Install dependencies
apt update && apt install -y debian-keyring debian-archive-keyring apt-transport-https git composer npm sudo caddy php php-fpm php-imagick php-gmp php-bcmath php-zip php-intl php-xml php-mbstring php-gd php-curl php-mysql mariadb-server mariadb-client dialog supervisor

# Caddy
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
apt install -y caddy

mkdir -p /etc/caddy/snippets

echo "import snippets/*" > /etc/caddy/Caddyfile

# MariaDB
mysql_secure_installation


# Hide processes from other users
echo "proc /proc proc defaults,hidepid=2 0 0" >> /etc/fstab
mount -o remount /proc
systemctl daemon-reload


# PHP Opcache
echo "# Custom config
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=100000
opcache.memory_consumption=512
opcache.save_comments=1
opcache.validate_permission = 1
opcache.revalidate_freq=1" >> /etc/php/8.2/fpm/php.ini
service php8.2-fpm restart


touch /opt/.easyweb
