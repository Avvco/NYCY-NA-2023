#!/bin/sh

# Function to unban an IP from a specific Fail2ban jail
unban_ip() {
    local ip="$1"
    local jail="$2"
    sudo fail2ban-client set "$jail" unbanip "$ip"
    echo "IP $ip unbanned from $jail"
}

# Main script logic
# if arguments are less than 3 or more than 3, display usage message
if [ "$#" -ne 3 ]; then
    echo "Usage: iamgoodguy <ip_address> -p <jail_name>"
    exit 1
fi

ip="$1"
protocol="$3"

case "$protocol" in
    "ssh")
        unban_ip "$ip" "sshd"
        ;;
    "web")
        unban_ip "$ip" "nginx-auth"  # Replace with your actual Nginx jail name if different
        ;;
    *)
        echo "Error: Invalid protocol. Use 'ssh' or 'web'."
        exit 1
        ;;
esac
