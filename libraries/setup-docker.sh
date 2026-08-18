_install_docker()
{
    echo "-----------------------------------"
    echo " > Docker Installation"
    echo "-----------------------------------"
    local device_type="$(. /etc/os-release && echo "${ID}")"
    # Instructions:
    # https://docs.docker.com/engine/install/ubuntu/

    _print_info "Removing 3rd party docker..."
    docker_to_remove=(
    "docker.io"
    "docker-doc"
    "docker-compose"
    "docker-compose-v2"
    "podman-docker"
    "containerd runc"
    )

    for func_name in "${docker_to_remove[@]}"; do
        if dpkg -s "${func_name}" >/dev/null 2>&1; then
            if sudo apt-get remove -y "${func_name}"; then
                _print_info "${func_name} removed."
            else
                _print_info "Unable to remove ${func_name} from the system."
            fi
        fi
    done

    _print_info "Starting Docker installation..."
    # Pull docker files and install
    sudo install -m 0755 -d "/etc/apt/keyrings"
    if sudo curl -fsSL "https://download.docker.com/linux/${device_type}/gpg" -o "/etc/apt/keyrings/docker.asc"; then
        sudo chmod a+r "/etc/apt/keyrings/docker.asc"
        sudo tee "/etc/apt/sources.list.d/docker.list" > /dev/null << EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${device_type} $(. /etc/os-release && echo "${VERSION_CODENAME}") stable
EOF
        _print_info "Docker repository inserted."

        sudo apt-get update
        if sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y; then
            docker --version
            _print_info "Docker installation successful."

            sudo usermod -aG docker "${USER}"
            _print_info "${USER} added to docker group."

            if sudo docker network inspect "${DOCKER_NETWORK_NAME}" >/dev/null 2>&1; then
                _print_info "Docker subnet network detected."
            else
                sudo docker network create \
                    --driver=bridge \
                    --subnet="${DOCKER_SUBNET_IP}" \
                    --gateway="${DOCKER_GATEWAY_IP}" \
                    "${DOCKER_NETWORK_NAME}"
                _print_info "Docker subnet network created."
            fi
        else
            _print_error "Docker installation failed."
        fi
    else
        _print_error "Docker repository insert failed."
    fi
}