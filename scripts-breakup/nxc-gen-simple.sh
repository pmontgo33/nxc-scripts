#!/bin/bash

# Sources


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

define_flake_repository (76-198)

gather_lxc_options (201-453)

define_base_template (455-545)

create_container (547-630)

verify_complete (632-)


