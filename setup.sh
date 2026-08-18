#!/bin/bash
set -euo pipefail

# ============================================== #
# PRINTS SHORTCUT
print_info(){
    echo "SYSTEM MSG: ${1:-}"
}
print_error(){
    echo "SYSTEM ERR: ${1:-}"
}
print_note(){
    echo "SYSTEM NOTE: ${1:-}"
}

# ============================================== #
# *
# ============================================== #
# SCRIPT VARIABLES
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${HOME}/git_repository"
CUDA_VER="13.0"     # Latest stable version 17/08/2026
DEVI_ENV="LINUX"    # Ubuntu
# ============================================== #
# *
# ============================================== #
# Check for device environment
if grep -qi microsoft /proc/version; then
    DEVI_ENV="WSL"
fi
# ============================================== #
# *
# ============================================== #
# Update Linux
echo "========================================"
echo " > Linux Update"
echo "========================================"
sudo apt-get update
sudo apt upgrade
sudo apt autoremove --purge
print_info "Linux updated."
# ============================================== #
# *
# ============================================== #
# Update Linux
echo "========================================"
echo " > SSH Creation"
echo "========================================"
if [[ -d "${HOME}/.ssh" ]]; then
    print_info "SSH has been setup on the device, SSH setup will be skipped."
else
    ssh-keygen -t ed25519
    print_info "SSH key has been created."
fi
# ============================================== #
# *
# ============================================== #
# Create Required folders
echo "========================================"
echo " > Project Repository Creation"
echo "========================================"
if [[ -d ${REPO_DIR} ]]; then
    print_info "Repository found, creation skipped."
else
    sudo mkdir -p ${REPO_DIR}
    sudo chown ${USER}:${USER} ${REPO_DIR}
    sudo chmod 774 ${REPO_DIR}
    print_info "${REPO_DIR} created."
fi
# ============================================== #
# *
# ============================================== #
# Installing dependencies
echo "========================================"
echo " > Project dependencies Installation"
echo "========================================"

sudo apt install -y \
    build-essential \
    wget \
    curl \
    ca-certificates \
    gnupg \
    pciutils

print_info "Project dependencies installed."
# ============================================== #
# *
# ============================================== #
# Install CUDA
echo "========================================"
echo " > NVIDIA Driver Installation"
echo "========================================"
ABORT_CUDA_INST=false
# # Verifying Drivers
if [ "$DEVI_ENV" = "LINUX" ]; then
    if command -v lspci >/dev/null 2>&1; then
        NVIDIA_HW=$(lspci | grep -i nvidia || true)
    else
        $SUDO apt update
        $SUDO apt install -y pciutils
        NVIDIA_HW=$(lspci | grep -i nvidia || true)
    fi

    if [ -z "NVIDIA_HW" ]; then
        if command -v nvidia-smi >/dev/null 2>&1; then
            print_info "NVIDIA driver is installed on Linux."
        else
            print_info "NVIDIA driver not found on Linux, installing drivers..."
            sudo apt install -y ubuntu-drivers-common || true
            if command -v ubuntu-drivers >/dev/null 2>&1; then
                ubuntu-drivers devices || true
                UBUNTU_DRIVER_LST=$(ubuntu-drivers list 2>/dev/null | tail -1)
                if [ -n "$DRIVER" ]; then
                    info "Installing recommended driver: $UBUNTU_DRIVER_LST"
                    if sudo apt install -y "$UBUNTU_DRIVER_LST"; then
                        print_info "Driver installed on Linux successfully."
                    else
                        ABORT_CUDA_INST=true
                        print_error "Error occured while installing drivers on Linux, CUDA installation aborted."
                    fi
                else
                    ABORT_CUDA_INST=true
                    print_error "Unable to determine drivers on Linux for installation, CUDA installation aborted."
                fi
            else
                ABORT_CUDA_INST=true
                print_error "Failed to install ubuntu drivers on Linux, CUDA installation aborted."
            fi
        fi
    else
        ABORT_CUDA_INST=true
        print_error "CUDA installation aborted, hardware type is unknown on Linux."
    fi
elif [ "$DEVI_ENV" = "WSL" ]; then
    if ! command -v nvidia-smi &> /dev/null; then
        ABORT_CUDA_INST=true
        print_note "nvidia-smi is not available on WSL..."
        print_note " > Verify if nvidia-smi is available on windows powershell."
        print_error "Unable to detect NVIDIA on WSL, CUDA installation aborted."
    else
        print_info "NVIDIA driver detected on WSL."
    fi
else
    ABORT_CUDA_INST=true
    print_error "CUDA installation aborted, unknown system environment."
fi

echo "========================================"
echo " > CUDA Toolkit Installation"
echo "========================================"
# # Initiate Driver installation
IS_CUDA_SUCCESS=false
if ! ${ABORT_CUDA_INST}; then
    print_info "Installing CUDA repository..."
    
    wget -q -O /tmp/cuda-keyring.deb \
        https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-keyring_1.1-1_all.deb
    
    sudo dpkg -i /tmp/cuda-keyring.deb
    sudo apt update
    
    print_info "Installing CUDA Toolkit..."
    if sudo apt-get install -y "cuda-toolkit-${CUDA_VER}"; then
        print_info "CUDA Toolkit installed successfully."
        if ! grep -q "/usr/local/cuda/bin" "$HOME/.bashrc"; then
            cat >> "$HOME/.bashrc" <<'EOF'
# CUDA
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

EOF
            export PATH=/usr/local/cuda/bin:$PATH
            export LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH:-}"
            print_info "CUDA path has been added into bashrc."
        else
            print_note "CUDA path exist in bashrc, skipping adding of path."
        fi
        IS_CUDA_SUCCESS=true
    else
        print_error "Failed to install CUDA Toolkit."
    fi
else
    print_note "CUDA installation aborted."
fi

echo "========================================"
echo " > CUDA Verification"
echo "========================================"
IS_CUDA_COMPILER_SUCCESS=false
IS_GPU_ACCESS_SUCCESS=false
if ${IS_CUDA_SUCCESS}; then
    print_info "Verifying CUDA Compiler"
    if command -v nvcc >/dev/null 2>&1; then
        nvcc --version
        print_info "CUDA compiler detected."
        IS_CUDA_COMPILER_SUCCESS=true
    else
        print_error "CUDA compiler not found."
    fi

    print_info "Verifying GPU access."
    if command -v nvidia-smi >/dev/null 2>&1; then
        print_info "Nvidia driver is accessible."
        IS_GPU_ACCESS_SUCCESS=true
    else
        print_error "nvidia-smi missing."
    fi

    if ${IS_CUDA_COMPILER_SUCCESS} && ${IS_GPU_ACCESS_SUCCESS}; then
        print_info "Testing CUDA environment..."
        cuda_test_dir="${SCRIPT_DIR}/cuda_test"
        mkdir -p "${cuda_test_dir}"
        cat > "${cuda_test_dir}/cuda_test.cu" <<'EOF'
#include <stdio.h>

__global__ void hello() {
    printf("Hello from CUDA\n");
}

int main() {
    hello<<<1,1>>>();
    cudaDeviceSynchronize();
    return 0;
}
EOF

        cd "${cuda_test_dir}"

        if nvcc cuda_test.cu -o ${cuda_test_dir}/cuda_test; then
            CUDA_OUTPUT=$("${cuda_test_dir}/cuda_test")
            if echo "$CUDA_OUTPUT" | grep -q "Hello from CUDA"; then
                print_info "CUDA execution successful."
            else
                print_error "CUDA test execution failed."
            fi
        else
            print_error "Failed to compile cuda object for test."
        fi
        sudo rm -R "${SCRIPT_DIR}/cuda_test"
    else
        print_error "CUDA verification failed."
    fi
else
    print_note "CUDA verification is not required."
fi
# ============================================== #
# *
# ============================================== #
# Install

# ============================================== #