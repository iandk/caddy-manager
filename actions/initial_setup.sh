if [ -f /opt/.easyweb ]; then
    exit
fi

apt update && apt install -y debian-keyring debian-archive-keyring apt-transport-https sudo caddy php php-fpm php-zip php-xml php-mbstring php-gd php-curl php-mysql mariadb-server mariadb-client dialog
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
apt install -y caddy
mysql_secure_installation
touch /opt/.easyweb