perform_initial_setup() {
    if [ -f /opt/.easyweb ]; then
        return
    fi
    apt update && apt install -y debian-keyring debian-archive-keyring apt-transport-https sudo caddy php php-fpm php-mysql mariadb-server mariadb-client dialog
    mysql_secure_installation
    touch /opt/.easyweb
}