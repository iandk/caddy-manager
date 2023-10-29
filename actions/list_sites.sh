list_sites() {
    file_path="/opt/site_accounts.txt"
    
    if [[ -f $file_path ]]; then
        # Use dialog's --menu option to allow selection
        while true; do
            # Dynamically create a menu with usernames and domains
            menu_items=()
            while IFS=',' read -r user domain; do
                menu_items+=("$user" "$domain")
            done < $file_path

            # Show the menu and get user selection
            choice=$(dialog --title "Accounts List" --menu "Choose a user to get its domain link" 20 60 10 "${menu_items[@]}" 3>&1 1>&2 2>&3 3>&-)

            exit_status=$?
            clear

            # If user pressed OK, display the domain in terminal
            if [[ $exit_status -eq 0 ]]; then
                domain_to_open=$(awk -F ',' -v user="$choice" '$1 == user {print $2}' $file_path)
                echo "Here is the domain link for $choice:"
                echo "https://$domain_to_open"
                echo "Click on the link to open it in your default browser."
                read -p "Press enter to continue..."
            else
                break
            fi
        done
    else
        dialog --title "Accounts List" --msgbox "No accounts found" 5 40
        clear
    fi
}
