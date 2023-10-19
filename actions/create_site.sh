domain=""
username=""

create_site() {
    get_site_details
    setup_system_user
    create_folder_structure
    create_php_fpm_pool
    create_caddy_config
    set_default_page
    create_database
}


get_site_details() {
    username=$(dialog --clear --inputbox "Enter username:" 8 40 3>&1 1>&2 2>&3 3>&-)
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

    domain=$(dialog --clear --inputbox "Enter domain:" 8 40 3>&1 1>&2 2>&3 3>&-)
    exit_status=$?
    clear
    if [ $exit_status != 0 ]; then
        clear
        exit 1
    fi

    userdir="/home/${username}/"
}

setup_system_user() {


    useradd -m "$username"
    usermod --shell /bin/bash "$username"
    usermod -a -G "$username" "$CADDY_USERNAME"
    passwd "$username"
    echo "$username,$domain" >> /opt/site_accounts.txt
    dialog --clear --title "Success" --msgbox "User $username successfully created" 5 40
    clear
}


create_folder_structure() {
    declare -a subfolders=("public" "files" "logs" "conf")
    for folder in "${subfolders[@]}"; do
        mkdir -p "${userdir}${folder}"
    done
    usermod -a -G $username $CADDY_USERNAME
    chown -R $username:$username $userdir
    chmod -R 770 $userdir
}

create_php_fpm_pool() {
    cp ../conf/www.conf $userdir/conf/www.conf
    chown $username:$username $userdir/conf/www.conf
    chmod 770 $userdir/conf/www.conf
    sed -i -e "s/{{USERNAME}}/${username}/g" \
           -e "s/-fpm.sock/-${username}-fpm.sock/g" \
           -e "s/\[www\]/[${username}]/g" "$userdir/conf/www.conf"
    echo "include=${userdir}conf/www.conf" >> "/etc/php/${OS_PHP_VERSION}/fpm/php-fpm.conf"
    service "php${OS_PHP_VERSION}-fpm" restart
}

create_caddy_config() {
    cat > $userdir/conf/Caddyfile <<EOF
$domain {
    root * ${userdir}public
    file_server
    encode gzip
    php_fastcgi unix//run/php/php${OS_PHP_VERSION}-${username}-fpm.sock {
        split .php
        index index.php
    }
}
EOF
    caddy fmt $userdir/conf/Caddyfile --overwrite
    chown caddy:caddy $userdir/conf/Caddyfile
    chmod 770 $userdir/conf/Caddyfile
    echo "import ${userdir}conf/Caddyfile" >> /etc/caddy/Caddyfile
    service caddy restart
}

set_default_page() {
    cat > $userdir/public/index.html <<EOF
    <!doctype html>
    <html>
    <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script src="https://cdn.tailwindcss.com"></script>
    </head>
    <body>
    <div class="flex h-screen flex-col justify-center text-center bg-slate-950">
    <h1 class="text-7xl font-bold text-white">$domain</h1>
    </div>
    </body>
    </html>
EOF
    chown $username:$username $userdir/public/index.html
    chmod 770 $userdir/public/index.html
}

create_database() {
    password=$(openssl rand -base64 12)
    mysql -u root <<EOF
CREATE DATABASE ${username}_db;
CREATE USER '${username}'@'localhost' IDENTIFIED BY '$password';
GRANT ALL PRIVILEGES ON ${username}_db.* TO '${username}'@'localhost';
FLUSH PRIVILEGES;
EOF
    echo -e "Database: ${username}_db\nUsername: ${username}\nPassword: $password" > "${userdir}/db_credentials.txt"
    chown ${username}:${username} "${userdir}/db_credentials.txt"
    chmod 600 "${userdir}/db_credentials.txt"
}
