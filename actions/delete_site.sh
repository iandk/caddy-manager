delete_site() {
    if [[ ! -f /opt/site_accounts.txt ]] || [[ ! -s /opt/site_accounts.txt ]]; then
        dialog --title "Error" --msgbox "No accounts to delete" 5 40
        clear
        return
    fi

    options=()
    while IFS=',' read -r username _; do
        options+=("$username" "")
    done < /opt/site_accounts.txt

    username_to_delete=$(dialog --menu "Choose an account to delete" 15 40 5 "${options[@]}" 3>&1 1>&2 2>&3)
    
    clear

    if [[ -n $username_to_delete ]]; then
        dialog --title "Confirm" --yesno "Are you sure you want to delete account $username_to_delete?" 6 40
        confirm=$?
        clear

        if [ $confirm -eq 0 ]; then
            sed -i "/^$username_to_delete,/d" /opt/site_accounts.txt

            # Remove the include and import lines from PHP-FPM and Caddy configurations
            sed -i "\|include=/home/${username_to_delete}/conf/www.conf|d" "/etc/php/${OS_PHP_VERSION}/fpm/php-fpm.conf"
            sed -i "\|import /home/${username_to_delete}/conf/Caddyfile|d" "/etc/caddy/Caddyfile"

            # Reload or restart services
            service "php${OS_PHP_VERSION}-fpm" restart
            service caddy reload 
            
            # Delete the user
            rm -r /home/$username_to_delete
            deluser "$username_to_delete"
            dialog --title "Success" --msgbox "Deleted account $username_to_delete" 5 40
        else
            dialog --title "Cancelled" --msgbox "Account deletion cancelled" 5 40
        fi
    fi

    clear
}