# NXC utils functions

# Function to convert KB to GB (Proxmox returns values in KB)
kb_to_gb() {
    local kb=$1
    if [[ "$kb" =~ ^[0-9]+$ ]]; then
        # Convert KB to GB with one decimal place
        # 1 GB = 1024 * 1024 = 1048576 KB
        local gb=$((kb / 1048576))
        local remainder=$((kb % 1048576))
        local decimal=$(( (remainder * 10) / 1048576 ))
        
        if [[ $decimal -eq 0 ]]; then
            echo "${gb}"
        else
            echo "${gb}.${decimal}"
        fi
    else
        echo "N/A"
    fi
}

# Function to validate CIDR format
validate_cidr() {
    local ip="$1"
    # Check if it matches basic CIDR format (IP/prefix)
    if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        # Extract IP and prefix
        local ip_part=$(echo "$ip" | cut -d'/' -f1)
        local prefix=$(echo "$ip" | cut -d'/' -f2)
        
        # Validate IP octets (0-255)
        IFS='.' read -ra octets <<< "$ip_part"
        for octet in "${octets[@]}"; do
            if [[ $octet -lt 0 || $octet -gt 255 ]]; then
                return 1
            fi
        done
        
        # Validate prefix (0-32)
        if [[ $prefix -lt 0 || $prefix -gt 32 ]]; then
            return 1
        fi
        
        return 0
    else
        return 1
    fi
}