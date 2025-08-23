# NXC Scripts

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![NixOS](https://img.shields.io/badge/NixOS-5277C3?logo=nixos&logoColor=white)](https://nixos.org/)
[![Proxmox](https://img.shields.io/badge/Proxmox-E57000?logo=proxmox&logoColor=white)](https://www.proxmox.com/)

> Automated scripts to create and manage NixOS LXCs (NXCs) on Proxmox VE hosts

NXC combines the declarative configuration power of NixOS with the portability and isolation benefits of Linux Containers. You can clone this repository and use the included examples, or point the scripts to your own Nix configuration repository to deploy and update your custom NXCs.

Is this the same as [Proxmox Helper Scripts](https://community-scripts.github.io/ProxmoxVE/scripts)? Yes and no. The helper scripts were my inspiration for creating this project. The helper scripts make it so simple to get an application up and running as an isolated container within Proxmox. NXC strives to do the same while combining the declaritive configuration of NixOS. This makes the code behind the scripts reproducible, customizable, and auditable. 

## 📚 Table of Contents

- [🚀 Quick Start](#-quick-start)
- [📋 Prerequisites](#-prerequisites)
- [📦 Installation](#-installation)
- [📖 Usage](#-usage)
- [🔧 Special Features](#-special-features)
- [🛠️ Troubleshooting](#️-troubleshooting)
- [📊 Compatibility](#-compatibility)
- [📚 Related Projects](#-related-projects)
- [📄 License](#-license)
- [🙏 Acknowledgments](#-acknowledgments)

## 🚀 Quick Start

```bash
# 1. Clone the repository on your NixOS system
git clone https://github.com/pmontgo33/nxc-scripts.git

# 2. Configure your environment by editing .env with your Proxmox and repository settings
cd nxc-scripts
nano scripts/.env

# 3. Create your first NXC
bash scripts/nxc-gen.sh
```

## 📋 Prerequisites

### System Requirements
- **NixOS system** to run the scripts from
- **SSH access** to your Proxmox VE host (key-based authentication recommended)
- **Git repository** containing your NixOS flake configuration, or use the examples in this repository
- **Nix flakes enabled** on your system

### Proxmox VE Requirements
- Proxmox VE 7.0 or 8.0 (not tested on 9.0, yet)
- Sufficient storage and resources for containers

### 🏗️ Flake Structure

Your `flake.nix` should define multiple host configurations as shown in the [flake.nix](flake.nix) in this repository. The scripts will automatically detect available hosts and allow you to select which configuration to deploy.

## 📦 Installation

### 1. Clone Repository to your existing NixOS System

```bash
git clone https://github.com/pmontgo33/nxc-scripts.git
```

### 2. Update Environment File (Optional)

Update the `.env` file in the `scripts/` directory to set default values and reduce prompts. See the [Network Configuration Options](#-network-configuration-options) to set the `DEFAULT_NETWORK_OPTION`


```bash
# Repository Configuration
REPOSITORY_URL="https://github.com/pmontgo33/nxc-scripts.git"
BRANCH="master"

# Proxmox Configuration
PVE_HOST="your-proxmox-hostname-or-ip-address"

# Default LXC Settings
DEFAULT_MEMORY="2048"
DEFAULT_CORES="2"
DEFAULT_DISK_SIZE="20"

# Default Network Settings
DEFAULT_NETWORK_OPTION="1"
DEFAULT_GATEWAY="192.168.1.1"
```

## 📖 Usage

### 🏗️ Create New NXC

Creates a new NixOS LXC from your flake configuration.

```bash
bash scripts/nxc-gen.sh
```

**Process:**
1. 🔍 Detects or prompts for Git repository and branch
2. 📋 Fetches available host configurations from your flake
3. ❓ Prompts for container settings (VMID, memory, cores, disk, network)
4. 🏗️ Generates or reuses NXC base template
5. 🚀 Creates and configures the LXC on Proxmox
6. 🔧 Rebuilds the container with your selected host configuration

**Features:**
- Automatic template generation and caching
- Network configuration (static IP or DHCP)
- Tailscale support detection and TUN device configuration
- Generation verification to ensure successful deployment

### 🔄 Update an Existing NXC

Updates an existing NixOS LXC container with the latest configuration from your flake.

```bash
bash scripts/nxc-update.sh
```

**Process:**
1. 🔍 Detects or prompts for Git repository and branch
2. 📋 Fetches available host configurations
3. 📃 Lists existing NixOS LXC containers on your Proxmox host
4. 🔧 Rebuilds selected container with updated configuration

## 🔧 Special Features

### 🌐 Network Configuration Options

When creating containers, you have three networking options:

| Option | Description | Use Case |
|--------|-------------|----------|
| **Static IP (Auto)** | `192.168.1.VMID/24` | Simple setups, predictable IPs |
| **DHCP** | Dynamic assignment | Quick testing, changing networks |
| **Custom Static** | User-defined IP/gateway | Complex network topologies |

### 🔒 Tailscale Support
The scripts automatically detect if your host configuration has Tailscale enabled and will configure TUN device access in the container configuration file.

### 📦 Template Caching
Base templates are cached on the Proxmox host to speed up subsequent container creation.

### ✅ Built-in Verification
- System status checks
- Hostname verification  
- Generation number validation
- Container runtime status

## 🛠️ Troubleshooting

<details>
<summary><strong>SSH Connection Issues</strong></summary>

- **SSH Access**: Ensure your user can SSH to the Proxmox host without password prompts
- Verify SSH key-based authentication is set up
- Test connection: `ssh root@your-proxmox-host`
</details>

<details>
<summary><strong>Flake Configuration Problems</strong></summary>

- **Flake Access**: Verify your Git repository is accessible and contains valid NixOS configurations
- Check that `nixosConfigurations` are properly defined
- Test locally: `nix flake show your-repo-url`
</details>

<details>
<summary><strong>Container Issues</strong></summary>

- **Container Startup**: Check Proxmox logs if containers fail to start
- **Network Issues**: Verify network settings match your Proxmox network configuration
- Check container logs: `pct exec VMID -- journalctl -f`
</details>



## 📊 Compatibility

| Component | Supported Versions |
|-----------|-------------------|
| **NixOS** | 22.11, 23.05, 23.11, unstable |
| **Proxmox VE** | 7.0+, 8.0+ |

## 📚 Related Projects

- [Proxmox Helper Scripts](https://community-scripts.github.io/ProxmoxVE/scripts) - Inspiration for simplicity
- [nixos-containers](https://github.com/NixOS/nixpkgs/tree/master/nixos/modules/virtualisation) - NixOS container modules
- [microvm.nix](https://github.com/astro/microvm.nix) - Lightweight NixOS VMs

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Special thanks to:
- The [Proxmox Helper Scripts](https://community-scripts.github.io/ProxmoxVE/scripts) community for inspiration - this project aims to be as simple as these helper scripts to deploy, with a Nix spin

---

<div align="center">

**[⭐ Star this repo](https://github.com/pmontgo33/nxc-scripts)** • **[🐛 Report Bug](https://github.com/pmontgo33/nxc-scripts/issues)** • **[💡 Request Feature](https://github.com/pmontgo33/nxc-scripts/issues)**

</div>