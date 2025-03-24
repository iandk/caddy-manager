create_site() {
    OS_PHP_VERSION="8.2"
    CADDY_USERNAME="caddy"

    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    CONF_DIR="${SCRIPT_DIR}/../conf"

    get_site_details
    setup_system_user
    create_folder_structure
    create_php_fpm_pool
    create_caddy_config
    set_default_page
    create_supervisor_config
    create_supervisor_cron
    create_database
}

get_site_details() {
    username=`dialog --stdout --clear --inputbox "Enter username:" 8 40`
    exit_status=$?
    clear
    if [ $exit_status != 0 ]; then
        clear
        exit 1
    fi

    if id "$username" &>/dev/null; then
        dialog --clear --title "Error" --msgbox "User $username already exists" 5 40
        clear
        exit 1
    fi

    domain=`dialog --stdout --clear --inputbox "Enter domain:" 8 40`
    exit_status=$?
    clear
    if [ $exit_status != 0 ]; then
        clear
        exit 1
    fi

    USERDIR="/home/${username}/"
}

setup_system_user() {
    useradd -m $username
    usermod --shell /bin/bash $username
    usermod -a -G $username $CADDY_USERNAME
    echo "$username,$domain" >> /opt/site_accounts.txt
    dialog --clear --title "Success" --msgbox "User $username successfully created" 5 40
}

create_folder_structure() {
    declare -a subfolders=("public" "files" "logs" "conf" "tmp" "bin" "run")
    for folder in "${subfolders[@]}"; do
        mkdir -p "${USERDIR}${folder}"
    done

    # Configure umask
    echo -e "\n# Custom config\n" >> "${USERDIR}/.bashrc"
    echo "umask 0007" >> "${USERDIR}/.bashrc"
    
    chown -R $username:$username $USERDIR
    chmod -R 770 $USERDIR
}

create_php_fpm_pool() {
    # Copy the template
    cp "${CONF_DIR}/php-fpm/www.conf" "${USERDIR}/conf/www.conf"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to copy PHP-FPM configuration file"
        echo "Source: ${CONF_DIR}/php-fpm/www.conf"
        echo "Destination: ${USERDIR}/conf/www.conf"
        exit 1
    fi
    
    # Create run directory for socket if it doesn't exist
    mkdir -p "${USERDIR}/run"
    chown $username:$username "${USERDIR}/run"
    chmod 770 "${USERDIR}/run"
    
    # Replace placeholders one at a time to avoid sed issues
    sed -i "s/\[www\]/[${username}]/g" "${USERDIR}/conf/www.conf"
    sed -i "s|{{USERNAME}}|${username}|g" "${USERDIR}/conf/www.conf"
    sed -i "s|{{SOCKFILE}}|/home/${username}/run/php${OS_PHP_VERSION}-${username}-fpm.sock|g" "${USERDIR}/conf/www.conf"
    
    # Set permissions
    chown $username:$username "${USERDIR}/conf/www.conf"
    chmod 770 "${USERDIR}/conf/www.conf"
    
    # Clean up any existing include in php-fpm.conf
    sed -i "\|include=${USERDIR}conf/www.conf|d" "/etc/php/${OS_PHP_VERSION}/fpm/php-fpm.conf"
    
    # Add fresh include
    echo "" >> "/etc/php/${OS_PHP_VERSION}/fpm/php-fpm.conf"
    echo "include=${USERDIR}conf/www.conf" >> "/etc/php/${OS_PHP_VERSION}/fpm/php-fpm.conf"
    
    # Validate the configuration before restarting
    if ! php-fpm${OS_PHP_VERSION} -t; then
        echo "Error: PHP-FPM configuration test failed"
        exit 1
    fi
    
    # Restart PHP-FPM
    systemctl restart "php${OS_PHP_VERSION}-fpm"
    
    # Check if the service started successfully
    if ! systemctl is-active --quiet "php${OS_PHP_VERSION}-fpm"; then
        echo "Error: PHP-FPM failed to restart"
        systemctl status "php${OS_PHP_VERSION}-fpm"
        exit 1
    fi
}

create_caddy_config() {
    # Create empty Caddyfile if it doesn't exist
    touch "${USERDIR}/conf/Caddyfile"
    
    # Add basic configuration
    cat > "${USERDIR}/conf/Caddyfile" <<EOF
${domain} {
    root * ${USERDIR}public
    php_fastcgi unix/${USERDIR}run/php${OS_PHP_VERSION}-${username}-fpm.sock
    file_server
    encode gzip
    log {
        output file ${USERDIR}logs/access.log
        format console
    }
}
EOF

    caddy fmt "${USERDIR}/conf/Caddyfile" --overwrite
    chown caddy:caddy "${USERDIR}/conf/Caddyfile"
    chmod 770 "${USERDIR}/conf/Caddyfile"
    
    # Add to main Caddy config if not already included
    grep -q "^import ${USERDIR}conf/Caddyfile" "/etc/caddy/Caddyfile" || \
        echo "import ${USERDIR}conf/Caddyfile" >> "/etc/caddy/Caddyfile"
    
    service caddy restart
}

set_default_page() {
    cp "${CONF_DIR}/index.html" "${USERDIR}/public/index.html"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to copy default index.html file"
        echo "Source: ${CONF_DIR}/index.html"
        echo "Destination: ${USERDIR}/public/index.html"
        exit 1
    fi
    
    sed -i -e "s/{{USERNAME}}/${username}/g" "${USERDIR}/public/index.html"
    chown $username:$username "${USERDIR}/public/index.html"
    chmod 770 "${USERDIR}/public/index.html"
}

create_supervisor_config() {
    # Add alias to avoid having to specify the configuration file each time
    echo "export SUPERVISOR_CONF=\$HOME'/conf/supervisord.conf'" >> "${HOME}/.bashrc"
    echo "alias supervisord='supervisord -c \$SUPERVISOR_CONF'" >> "${HOME}/.bashrc"
    echo "alias supervisorctl='supervisorctl -c \$SUPERVISOR_CONF'" >> "${HOME}/.bashrc"
}

create_supervisor_cron() {
    # Add cron job to start supervisor on boot
    sudo -u $username bash -c '(crontab -l 2>/dev/null; echo "@reboot supervisord -c $HOME/conf/supervisord.conf") | crontab -'
}

create_database() {
    password=$(openssl rand -base64 12)
    mysql -u root <<EOF
CREATE DATABASE \`${username}_db\`;
CREATE USER '${username}'@'localhost' IDENTIFIED BY '$password';
GRANT ALL PRIVILEGES ON \`${username}_db\`.* TO '${username}'@'localhost';
FLUSH PRIVILEGES;
EOF
    echo -e "Database: ${username}_db\nUsername: ${username}\nPassword: $password" > "${USERDIR}/db_credentials.txt"
    chown ${username}:${username} "${USERDIR}/db_credentials.txt"
    chmod 600 "${USERDIR}/db_credentials.txt"
}
