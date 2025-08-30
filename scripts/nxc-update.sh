#!/bin/bash

# Get the directory where the script is located and source common functions
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/common.sh"

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

# Setup repository, branch, and flake URL
setup_repository
setup_branch
setup_flake_url

# Select hostname from flake
select_hostname

# LXC Identification
echo "Select NXC to Update:"
echo "-------------------------------------"

# Setup Proxmox host
setup_proxmox_host
echo

# List available NixOS LXCs and get selection
list_nixos_lxcs "$pve_host"

# Select VMID from available options
select_vmid "${valid_vmids[@]}"

# Configure Tailscale if needed
configure_tailscale "$vmid" "$hostname" "$pve_host"

# Ensure container is running
ensure_container_running "$vmid" "$pve_host"

echo
echo "Container is running. Beginning rebuild with $hostname configuration..."
echo

# Get container IP
get_container_ip "$vmid" "$pve_host"

# Perform nixos-rebuild and get initial generation
initial_generation=$(perform_rebuild "$vmid" "$hostname" "$pve_host")

# Perform final verification
final_success=$(perform_final_verification "$vmid" "$hostname" "$pve_host" "$initial_generation" "$container_ip")

# Display final results
display_final_results "$final_success" "$vmid" "$hostname" "$container_ip" "N/A" "update"

exit 1