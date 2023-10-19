deploy_application() {
    # Check if there are any accounts to deploy to
    if [[ ! -f /opt/site_accounts.txt ]] || [[ ! -s /opt/site_accounts.txt ]]; then
        dialog --title "Error" --msgbox "No accounts available for application deployment" 5 40
        clear
        return
    fi

    # Read accounts into options
    options=()
    while IFS=',' read -r username _; do
        options+=("$username" "")
    done < /opt/site_accounts.txt

    deploy_to_user=$(dialog --menu "Choose an account to deploy to" 15 40 5 "${options[@]}" 3>&1 1>&2 2>&3)
    clear

    # Read available templates into app_options
    app_options=()
    for f in templates/*.sh; do
        app_name=$(basename "$f" .sh)
        app_options+=("$app_name" "")
    done

    chosen_app=$(dialog --menu "Choose an application to deploy" 15 40 5 "${app_options[@]}" 3>&1 1>&2 2>&3)
    clear

    if [[ -n $deploy_to_user && -n $chosen_app ]]; then
        userdir="/home/${deploy_to_user}/"
        bash "templates/$chosen_app.sh" "$userdir"  # Assuming the script takes userdir as an argument
        dialog --title "Success" --msgbox "Successfully deployed $chosen_app to $deploy_to_user" 5 40
    else
        dialog --title "Cancelled" --msgbox "Application deployment cancelled" 5 40
    fi

    clear
}