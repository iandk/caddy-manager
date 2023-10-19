require_root_user() {
    if [[ $EUID -ne 0 ]]; then
        dialog --title "Permission Denied" --msgbox "This script must be run as root" 5 40
        clear
        exit 1
    fi
}