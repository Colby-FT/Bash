#!/bin/bash
#This is intended to restrict access to the vCenter server via ssh and https by IP address.
#Remember to add the IPs of your ESXi hosts, or they will lose connectivity to the vCenter server.
#This creates a deny any rule for SSH (port 22) and HTTPS (port 443), then explicitly allows specific IPs to access those ports and port 902. This does not restrict any other ports.

# Define allowed IPs
ALLOWED_IPS=()
#example: ALLOWED_IPS=(172.17.28.22 172.17.28.21 172.17.28.9)

# Start and enable iptables service
systemctl start iptables
systemctl enable iptables

# Allow loopback and established connections
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Drop incoming SSH 22 & HTTPS 443 from all IPs
iptables -A INPUT -p tcp --dport 22 -j DROP
iptables -A INPUT -p tcp --dport 443 -j DROP

# Explicitly allow incoming 22, 443, and 902 from allowed IPs
for ip in "${ALLOWED_IPS[@]}"; do
  iptables -I INPUT -p tcp -s "$ip" --dport 22 -j ACCEPT
  iptables -I INPUT -p tcp -s "$ip" --dport 443 -j ACCEPT
  iptables -I INPUT -p tcp -s "$ip" --dport 902 -j ACCEPT
  iptables -I INPUT -p udp -s "$ip" --dport 902 -j ACCEPT
done

# Explicitly allow outbound traffic on ports 22, 443, and 902
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 902 -j ACCEPT
iptables -A OUTPUT -p udp --dport 902 -j ACCEPT

# Save rules
iptables-save > /etc/systemd/scripts/ip4save

# Print new rules for verification
echo "New iptables rules:"
iptables -L -n