# NXC Scripts

This repository provides automated scripts to create and manage NixOS LXCs (NXCs) on Proxmox VE hosts. NXC combines the declarative configuration power of NixOS with the portability and isolation benefits of Linux Containers.

You can clone this repository and create NXCs using the examples in this script, or you can point the scripts to your own nix configuration repository and deploy/update your own custom NXCs.

## Overview

The NXC scripts automate the process of:
- Building NixOS LXC templates from a Nix flake configuration
- Creating new LXC containers on Proxmox VE hosts
- Updating existing containers with new configurations
- Managing container networking and special features (like Tailscale support)

## Prerequisites

### System Requirements
- A NixOS system to run the scripts from
- SSH access to your Proxmox VE host
- Git repository containing your NixOS flake configuration
- Nix flakes must be enabled on your system

### Flake Structure
Your flake.nix should define multiple host configurations as shown in the examples in this repository. The scripts will automatically detect available hosts and allow you to select which configuration to deploy.

## Installation

### 1. Clone Repository to your existing NixOS System

```bash
mkdir nxc-scripts
cd nxc-scripts
git clone https://github.com/pmontgo33/nxc-scripts.git
```

### 2. Update Environment File (optional)
Update the `.env` file in the `scripts/` directory to set default values and reduce prompts:

```bash
# Repository Configuration
REPOSITORY_URL="https://github.com/pmontgo33/nix-config.git"
BRANCH="master"

# Proxmox Configuration
PVE_HOST="your-proxmox-hostname-or-ip-address"

# Default LXC Settings
DEFAULT_MEMORY="2048"
DEFAULT_CORES="2"
DEFAULT_DISK_SIZE="20"

# Default Network Settings
DEFAULT_NETWORK_OPTION="1"
DEFAULT_GATEWAY="192.168.86.1"

```
### 2. Run one of the Scripts

## Scripts

### Create New NXC

Creates a new NixOS LXC from your flake configuration.

**Usage:**
```bash
bash scripts/nxc-gen.sh
```

**Process:**
1. Detects or prompts for Git repository and branch
2. Fetches available host configurations from your flake
3. Prompts for container settings (VMID, memory, cores, disk, network)
4. Generates or reuses NXC base template
5. Creates and configures the LXC on Proxmox
6. Rebuilds the container with your selected host configuration

**Features:**
- Automatic template generation and caching
- Network configuration (static IP or DHCP)
- Tailscale support detection and TUN device configuration
- Generation verification to ensure successful deployment

### Update an Existing NXC

Updates an existing NixOS LXC container with the latest configuration from your flake.

**Usage:**
```bash
bash scripts/nxc-update.sh
```

**Process:**
1. Detects or prompts for Git repository and branch
2. Fetches available host configurations
3. Lists existing NixOS LXC containers on your Proxmox host
4. Rebuilds selected container with updated configuration

## Network Configuration Options

When creating containers, you have three networking options:

1. **Static IP (192.168.1.VMID/24)** - Automatic IP based on container VMID
2. **DHCP** - Dynamic IP assignment
3. **Custom Static IP** - Specify your own IP address and gateway

## Special Features

### Tailscale Support
The scripts automatically detect if your host configuration has Tailscale enabled and will configure TUN device access in the container configuration file

### Template Caching
Base templates are cached on the Proxmox host to speed up subsequent container creation.

## Troubleshooting

### Common Issues

- **SSH Access**: Ensure your user can SSH to the Proxmox host without password prompts
- **Flake Access**: Verify your Git repository is accessible and contains valid NixOS configurations
- **Container Startup**: Check Proxmox logs if containers fail to start
- **Network Issues**: Verify network settings match your Proxmox network configuration

### Verification Steps

The scripts perform automatic verification including:
- System status checks
- Hostname verification  
- Generation number validation
- Container runtime status


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

I am a frequent user of [Promox Helper Scripts](https://community-scripts.github.io/ProxmoxVE/scripts). This project is aiming to be as simple as these helper scripts to deploy, with a nix-spin.