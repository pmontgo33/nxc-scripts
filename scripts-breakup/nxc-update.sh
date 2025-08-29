#!/bin/bash
source lib/common.sh

# Clear the terminal
clear

# Welcome message
echo "This script will update an existing NixOS LXC container based on a host from your flake.nix"
echo "----------------------------------------------------------------------------------"
echo "Prerequisite: This script must run on a system with ssh access to the Proxmox VE host"
echo
echo "Press Enter to continue..."
read
echo "================================================================"
echo

# Load environment variables from .env file
if load_env_file; then
    echo "Found .env file, checking for configuration..."
    echo
else
    echo "No .env file found in current directory, continuing with user prompts..."
    echo
fi
echo "================================================================"
echo
echo "Define Flake Repository"
echo "-------------------------"

fetch_flake_repository

# LXC Identification
echo "Select NXC to Update:"
echo "-------------------------------------"

fetch_pve_host

echo "NixOS LXCs on this Proxmox host:"
nixos_lxcs=()
valid_vmids=()

for vmid in $(ssh "root@$pve_host" "pct list" | awk 'NR>1 {print $1}'); do
    if ssh "root@$pve_host" "pct config '$vmid'" | grep -q "ostype: nixos"; then
        name=$(ssh "root@$pve_host" "pct list" | awk -v id="$vmid" '$1==id {print $3}')
        nixos_lxcs+=("$vmid:$name")
        valid_vmids+=("$vmid")
    fi
done

for lxc in "${nixos_lxcs[@]}"; do
    vmid_display="${lxc%%:*}"
    name="${lxc#*:}"
    echo "$vmid_display. $name"
done

# Prompt user for VMID selection
while true; do
    echo
    read -p "Enter the VMID for the NXC to be updated: " vmid
    
    # Check if input is blank
    if [[ -z "$vmid" ]]; then
        echo "Error: VMID cannot be blank. Please try again."
        continue
    fi
    
    # Check if VMID exists in our valid list
    if [[ " ${valid_vmids[*]} " == *" $vmid "* ]]; then
        break
    else
        echo "Error: '$vmid' is not a valid VMID from the list. Please try again."
    fi
done

echo "You selected VMID $vmid"
echo
echo "================================================================"
echo
    
tailscale_tun_config

echo
echo "================================================================"
echo

confirm_lxc_running

rebuild_nxc

echo
echo "================================================================"
echo

perform_nxc_verification

echo
echo "======================================================================"
echo
exit 1