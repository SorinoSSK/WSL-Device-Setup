_verify_linux_env()
{
    if grep -qi microsoft /proc/version; then
        DEVICE_ENV="WSL"
    fi
    _print_info "Detected Linux Environment: ${DEVICE_ENV}"
    echo
}

_update_linux()
{
    echo "========================================"
    echo " > Linux Update"
    echo "========================================"
    sudo apt-get update
    sudo apt upgrade -y
    sudo apt autoremove -y --purge
    echo
    _print_info "Linux updated."
}

_ssh_creation()
{
    echo "========================================"
    echo " > SSH Creation"
    echo "========================================"
    if [[ -d "${HOME}/.ssh" ]]; then
        _print_info "SSH Configuration Detected."
    else
        ssh-keygen -t ed25519
        _print_info "SSH Configuration Completed."
    fi
}

_create_default_directories()
{
    echo "========================================"
    echo " > Project Root Repository Creation"
    echo "========================================"
    if [[ -d ${REPO_DIR} ]]; then
        _print_info "Repository Detected."
    else
        sudo mkdir -p ${REPO_DIR}
        sudo chown ${USER}:${USER} ${REPO_DIR}
        sudo chmod 774 ${REPO_DIR}
        _print_info "Repository '${REPO_DIR}' Created."
    fi
}

_install_dependencies()
{
    echo "========================================"
    echo " > Dependencies Installation"
    echo "========================================"

    if _array_empty_check "PKGS_LST"; then
        for pkgs in "${PKGS_LST[@]}"; do
            sudo apt install -y "${pkgs}"
        done
        _print_info "Dependencies installed."
    else
        _print_error "Package List is Empty."
    fi
}