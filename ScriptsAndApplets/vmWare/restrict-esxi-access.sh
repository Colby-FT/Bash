#!/bin/bash

#This is intended to lock down the ESXi firewall to only allow access from specific IP addresses.
#Remember to add the vCenter IP address to the ALLOWED_IPS array.
#Remember to include your IP addresses in the ALLOWED_IPS array.

#Assign Variables
ALLOWED_IPS=()
#example: ALLOWED_IPS=(172.17.28.22 172.17.28.21 172.17.28.9)

#Enable the firewall
esxcli network firewall set --enabled true;

#Deny all by default for sshServer, webAccess, and vSphereClient. Then allow IPs from ALLOWED_IPS array.
for RULESET in sshServer webAccess vSphereClient; do
  esxcli network firewall ruleset set -e true -r "$RULESET" --allowed-all false
  for IP in "${ALLOWED_IPS[@]}"; do
    esxcli network firewall ruleset allowedip add -r "$RULESET" -i "$IP"
  done
done

#Restart the firewall and services to apply changes
esxcli network firewall refresh;

#Restart all services to ensure the changes take effect. Warning: This may disrupt current connections between the host and vCenter.
services.sh restart; 

