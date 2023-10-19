list_sites() {
    if [[ -f /opt/site_accounts.txt ]]; then
        formatted_list=$(awk -F ',' '{ printf "User: %-15s | Domain: %-15s\n", $1, substr($2, 1, 15) }' /opt/site_accounts.txt)
        dialog --title "Accounts List" --msgbox "$formatted_list" 20 60
    else
        dialog --title "Accounts List" --msgbox "No accounts found" 5 40
    fi
    clear
}