#!/bin/bash
source lib/common.sh
source lib/utils.sh

# Clear the terminal
clear

# Welcome message
echo "This script will create a NixOS LXC container based on a host from your flake.nix"
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

# LXC Basics
echo "LXC Basic Configuration Options:"
echo "-------------------------------------"

fetch_pve_host

# Query Proxmox VE host for available storage
storage_info=$(ssh "root@$pve_host" "pvesm status --content images --enabled 1" 2>/dev/null | tail -n +2)
if [[ -z "$storage_info" ]]; then
    echo "Error: No container-compatible storage found on $host"
    exit 1
fi

# Get next available VMID
next_vmid=$(ssh "root@$pve_host" "pvesh get /cluster/nextid 2>/dev/null" 2>/dev/null)
read -p "Enter VMID [$next_vmid]: " vmid

# Prompt for hostname
read -p "Enter NXC Hostname [$hostname]: " nxc_hostname
# Set nxc_hostname to flake hostname if empty
if [ -z "$nxc_hostname" ]; then
    nxc_hostname="$hostname"
fi

# Set VMID to next_vmid if empty
if [ -z "$vmid" ]; then
    vmid="$next_vmid"
fi
echo

# Prompt for root password
echo -n "Enter root password: "
read -s password
echo

# Check if password was entered
if [ -z "$password" ]; then
    echo "Error: No password entered"
    exit 1
fi

# Prompt for password confirmation
echo -n "Confirm password: "
read -s password_confirm
echo

# Check if passwords match
if [ "$password" != "$password_confirm" ]; then
    echo "Error: Passwords do not match"
    # Clear both password variables for security
    unset password password_confirm
    exit 1
fi

echo
echo "Passwords match successfully!"
echo

# Prompt for Memory
if [ -n "$ENV_DEFAULT_MEMORY" ]; then
    read -p "Enter Memory (MB) [$ENV_DEFAULT_MEMORY]: " memory
    if [ -z "$memory" ]; then
        memory="$ENV_DEFAULT_MEMORY"
        echo "$memory MB"
    fi
else
    read -p "Enter Memory (MB): " memory
fi

# Prompt for Cores
if [ -n "$ENV_DEFAULT_CORES" ]; then
    read -p "Enter Cores [$ENV_DEFAULT_CORES]: " cores
    if [ -z "$cores" ]; then
        cores="$ENV_DEFAULT_CORES"
        echo "$cores cores"
    fi
else
    read -p "Enter Cores: " cores
fi

# List available storage options on PVE host
echo
echo "Available storage options for containers:"
echo "========================================="
printf "%-3s | %-12s | %-8s | %-8s | %-10s | %-9s | %-10s | %s\n" "ID" "Name" "Type" "Status" "Total (GB)" "Used (GB)" "Avail (GB)" "Usage%"
echo "----+--------------+----------+----------+------------+-----------+------------+---------"
# Parse and display storage options with index numbers
counter=1
storage_names=()

while IFS= read -r line; do
    if [[ -n "$line" ]]; then
        # Parse the line fields
        storage_name=$(echo "$line" | awk '{print $1}')
        storage_type=$(echo "$line" | awk '{print $2}')
        storage_status=$(echo "$line" | awk '{print $3}')
        total_value=$(echo "$line" | awk '{print $4}')
        used_value=$(echo "$line" | awk '{print $5}')
        avail_value=$(echo "$line" | awk '{print $6}')
        usage_percent=$(echo "$line" | awk '{print $7}')
        
        storage_names+=("$storage_name")
        
        # Convert KB to GB
        total_gb=$(kb_to_gb "$total_value")
        used_gb=$(kb_to_gb "$used_value")
        avail_gb=$(kb_to_gb "$avail_value")
        
        # Format and display the line with proper spacing
        printf "%-3d | %-12s | %-8s | %-8s | %10s | %9s | %10s | %s\n" \
            "$counter" "$storage_name" "$storage_type" "$storage_status" \
            "${total_gb}GB" "${used_gb}GB" "${avail_gb}GB" "$usage_percent"
        ((counter++))
    fi
done <<< "$storage_info"

echo

# Prompt for storage
read -p "Select storage (1-$((counter-1))): " selection
echo
# Validate input
if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -lt "$counter" ]; then
    selected_storage="${storage_names[$((selection-1))]}"
    echo "Selected storage: $selected_storage"
    echo
else
    echo "Invalid selection!"
    exit 1
fi

# Prompt for Disk Size
if [ -n "$ENV_DEFAULT_DISK_SIZE" ]; then
    read -p "Enter Disk Size (GB) [$ENV_DEFAULT_DISK_SIZE]: " disk_size
    if [ -z "$disk_size" ]; then
        disk_size="$ENV_DEFAULT_DISK_SIZE"
        echo "$disk_size GB"
    fi
else
    read -p "Enter Disk Size (GB): " disk_size
fi
echo
echo "================================================================"
echo

while true; do
    # IP Address selection with options
    echo "Network Configuration:"
    echo "---------------------------"
    echo "1) DHCP"

    if [ -n "$ENV_DEFAULT_GATEWAY" ]; then
        subnet="${ENV_DEFAULT_GATEWAY%.*}"
        echo "2) Static IP $subnet.$vmid/24 (Gateway: $ENV_DEFAULT_GATEWAY)"
    fi
    echo "Other enter custom Static IP address"
    echo
    
    # Handle default network option from .env
    if [ -n "$ENV_DEFAULT_NETWORK_OPTION" ]; then
        read -p "Select network option (1, 2) or enter custom IP address (e.g., 192.168.x.$vmid/24) [$ENV_DEFAULT_NETWORK_OPTION]: " ip_selection
        if [ -z "$ip_selection" ]; then
            ip_selection="$ENV_DEFAULT_NETWORK_OPTION"
            echo "Using default network option from .env: $ip_selection"
        fi
    else
        read -p "Select network option (1, 2) or enter custom IP address (e.g., 192.168.x.$vmid/24): " ip_selection
    fi

    case "$ip_selection" in
        1)
            ip_address="dhcp"
            gateway=""
            break
            ;;
        2)
            ip_address="192.168.86.$vmid/24"
            gateway="192.168.86.1"
            break
            ;;
        *)
            # Check if it's a custom IP address
            if validate_cidr "$ip_selection"; then
                ip_address="$ip_selection"
                # Prompt for gateway for custom IP
                read -p "Enter Gateway: " gateway
                break
            else
                echo "Invalid selection or IP format. Please enter 1, 2, or a valid CIDR address (e.g., 192.168.86.$vmid/24)"
                echo
            fi
            ;;
    esac
done

# Build network configuration
net_config="name=eth0,bridge=vmbr0,ip=$ip_address"
if [[ "$ip_address" != "dhcp" && "$ip_address" != "DHCP" && -n "$gateway" ]]; then
    net_config="$net_config,gw=$gateway"
fi

echo
echo "================================================================"
echo

echo "Choose how you’d like to define the base template..."
echo
echo "1. Select an existing NXC base template from your PVE Host $pve_host"
echo "2. Generate a new NXC base template with nixos-generate (requires running on an existing NixOS System)"
echo "3. Use pre-generated nxc-base template from NXC-Scripts repository"
echo
read -p "Enter an option: " selection
echo
if [ "$selection" = "1" ]; then
    # Check for existing NXC Templates on PVE Host
    echo "Checking PVE Host $pve_host for existing NXC base templates..."
    nxc_templates=$(ssh "root@$pve_host" "pveam list local | grep nxc-base" | awk '{print $1}' | sed 's|.*:vztmpl/||')
    if [ -n "$nxc_templates" ]; then
        echo "Available NXC base templates on $pve_host:"
        echo "----------------------------------------------"
        echo "$nxc_templates" | nl -w2 -s'. '
        echo
    fi
    # Prompt for template
    read -p "Select an existing NXC base template by number or press enter to generate new: " template_selection
    
    # Check if the input is a number (matches a line number)
    if [[ "$template_selection" =~ ^[0-9]+$ ]]; then
        # Extract the corresponding template based on the number
        template_filename=$(echo "$nxc_templates" | sed -n "${template_selection}p")
    fi
    # Check if the template actually exists in the list
    if ! echo "$nxc_templates" | grep -Fxq "$template_filename"; then
        echo "Invalid selection."
        exit 1
    fi

    echo "You selected template $template_filename."
    echo
    echo "================================================================"
    echo
    template_path="/var/lib/vz/template/cache/$template_filename"

elif [ "$selection" = "2" ]; then
    # Run nixos-generate command with the base template
    echo "Generating new NXC Base template (this may take several minutes)..."
    output_dir=./base-template
    nixos-generate -f proxmox-lxc \
    --flake "$flake_base_url#nxc-base" \
    -o "$output_dir"
    echo
    sleep 5
    echo "New NXC Base template generation complete!"
    echo

    # Find the template filename
    template_filename=$(find "$output_dir/tarball" -name "*.tar.xz" -exec basename {} \; 2>/dev/null | head -n1)

    if [ -z "$template_filename" ]; then
        echo "Error: Could not find template file in $output_dir/tarball"
        exit 1
    fi
    template_path="/var/lib/vz/template/cache/nxc-base-$template_filename"

    # Copy template to Proxmox host
    echo "Copying template to Proxmox host $pve_host..."
    scp "$output_dir/tarball/$template_filename" "root@$pve_host:$template_path"
    echo
    
elif [ "$selection" = "3" ]; then
    echo "Using pre-generated nxc-base template from NXC-Scripts repository"
    # Find the template filename
    output_dir=./base-template
    template_filename=$(find "$output_dir/tarball" -name "*.tar.xz" -exec basename {} \; 2>/dev/null | head -n1)

    if [ -z "$template_filename" ]; then
        echo "Error: Could not find template file in $output_dir/tarball"
        exit 1
    fi
    template_path="/var/lib/vz/template/cache/nxc-base-$template_filename"

    # Copy template to Proxmox host
    echo "Copying template to Proxmox host $pve_host..."
    scp "$output_dir/tarball/$template_filename" "root@$pve_host:$template_path"
    echo
    
else
    echo "Error: Invalid selection. Please choose 1, 2, or 3."
    exit 1
fi

# Create the container
echo "Creating container on Proxmox host $pve_host..."
ssh "root@$pve_host" "pct create $vmid $template_path --hostname $nxc_hostname --memory $memory --cores $cores --rootfs $selected_storage:$disk_size --unprivileged 1 --features nesting=1 --onboot 1 --tags nixos --net0 $net_config"
echo
echo "================================================================"
echo

tailscale_tun_config

echo
echo "================================================================"
echo


# Start NixOS LXC Base container
echo "Starting LXC container for configuration phase..."
ssh "root@$pve_host" "pct start $vmid"
echo

confirm_lxc_running

rebuild_nxc

echo
echo "================================================================"
echo

# Change root password
echo "Setting root password on new host $nxc_hostname"
ssh "root@$pve_host" "pct exec $vmid -- /run/current-system/sw/bin/sh -c 'echo \"root:$password\" | /run/current-system/sw/bin/chpasswd'"
echo
echo "================================================================"
echo

# Clear both password variables for security
unset password password_confirm

perform_nxc_verification

echo
echo "======================================================================"
echo
exit 1