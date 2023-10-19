#!/bin/bash
source actions/require_root_user.sh
source actions/create_site.sh
source actions/list_sites.sh
source actions/delete_site.sh
source actions/deploy_app.sh

export username
export domain
export userdir

set -e


require_root_user

# Perform the initial setup
bash actions/initial_setup.sh

# Main Flow
while true; do
    cmd=(dialog --title "Menu" --menu "Choose an action" 15 50 5)
    options=(1 "Create new site"
             2 "List sites"
             3 "Delete site"
             4 "Deploy app"
             5 "Quit")
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    clear

    case $choice in
        1)
            create_site
            ;;
        2)
            list_sites 
            ;;
        3)
            delete_site 
            ;;
        4)
            deploy_app 
            ;;
        5)
            clear
            exit 0
            ;;
        *)
            dialog --title "Menu" --msgbox "Invalid option, exiting..." 5 40
            clear
            exit 1
            ;;
    esac

    clear
done
