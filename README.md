# NXC Scripts

This repository provides automated scripts to create and manage NixOS LXCs (NXCs) on Proxmox VE hosts. NXC combines the declarative configuration power of NixOS with the portability and isolation benefits of Linux Containers.

## Overview

The NXC scripts automate the process of:
- Building NixOS LXC templates from a Nix flake configurations
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
Your NixOS flake should define multiple host configurations in `nixosConfigurations`. The scripts will automatically detect available hosts and allow you to select which configuration to deploy.

Example flake structure:
```nix
{
  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations = {
      nxc-base = nixpkgs.lib.nixosSystem { ... };
      nxc-tailscale = nixpkgs.lib.nixosSystem { ... };
      nix-fury = nixpkgs.lib.nixosSystem { ... };
      omnitools = nixpkgs.lib.nixosSystem { ... };
    };
  };
}
```

## Configuration

### Environment File (.env)
Create a `.env` file in the `scripts/` directory to set default values and reduce prompts:

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

## Scripts

### nxc-gen.sh - Create New NXC

Creates a new NixOS LXC from your flake configuration.

**Usage:**
```bash
cd scripts/
./nxc-gen.sh
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

### nxc-update.sh - Update Existing NXC Container

Updates an existing NixOS LXC container with the latest configuration from your flake.

**Usage:**
```bash
cd scripts/
./nxc-update.sh
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
The scripts automatically detect if your host configuration has Tailscale enabled and will:
- Configure TUN device access in the container
- Add necessary LXC configuration for VPN functionality

### Template Caching
Base templates are cached on the Proxmox host to speed up subsequent container creation.

## Example Workflow

1. **Set up environment:**
   ```bash
   cp scripts/.env.example scripts/.env
   # Edit .env with your settings
   ```

2. **Create a new container:**
   ```bash
   cd scripts/
   ./nxc-gen.sh
   ```

3. **Update an existing container:**
   ```bash
   cd scripts/
   ./nxc-update.sh
   ```

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