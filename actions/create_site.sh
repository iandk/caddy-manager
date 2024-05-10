create_site() {
    OS_PHP_VERSION="8.2"
    CADDY_USERNAME="caddy"

    get_site_details
    setup_system_user
    create_folder_structure
    create_php_fpm_pool
    create_caddy_config
    set_default_page
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
    echo -e "\n# Custom config\n" >> $USERDIR/.bashrc
    echo "umask 0007" >> $USERDIR/.bashrc
    
    chown -R $username:$username $USERDIR
    chmod -R 770 $USERDIR
}

create_php_fpm_pool() {
    pwd
    cp conf/www.conf $USERDIR/conf/www.conf
    chown $username:$username $USERDIR/conf/www.conf
    chmod 770 $USERDIR/conf/www.conf
    sed -i -e "s/{{USERNAME}}/${username}/g" \
           -e "s/-fpm.sock/-${username}-fpm.sock/g" \
           -e "s/\[www\]/[${username}]/g" "$USERDIR/conf/www.conf"
    echo -e "\ninclude=${USERDIR}conf/www.conf" >> "/etc/php/${OS_PHP_VERSION}/fpm/php-fpm.conf"
    echo -e "\nphp_admin_value[opcache.restrict_api] = /home/${username}/public" >> "$USERDIR/conf/www.conf"
    service "php${OS_PHP_VERSION}-fpm" restart
}

create_caddy_config() {
    caddy fmt $USERDIR/conf/Caddyfile --overwrite
    chown caddy:caddy $USERDIR/conf/Caddyfile
    chmod 770 $USERDIR/conf/Caddyfile
    echo "import ${USERDIR}conf/Caddyfile" >> /etc/caddy/Caddyfile
    service caddy restart
}

set_default_page() {
    cp -a conf/index.html $USERDIR/public/index.html
    sed -i -e "s/{{USERNAME}}/${username}/g" $USERDIR/public/index.html
    chown $username:$username $USERDIR/public/index.html
    chmod 770 $USERDIR/public/index.html
}

create_supervisor_config() {
    # Add alias to avoid having to specify the configuration file each time
    echo "export SUPERVISOR_CONF=\$HOME'/conf/supervisord.conf'" >> $HOME/.bashrc
    echo "alias supervisord='supervisord -c \$SUPERVISOR_CONF'" >> $HOME/.bashrc
    echo "alias supervisorctl='supervisorctl -c \$SUPERVISOR_CONF'" >> $HOME/.bashrc

    source $HOME/.bashrc
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

