_install_cuda()
{
    echo "========================================"
    echo " > CUDA Installation"
    echo "========================================"
    local abort_installation=false is_cuda_success=false is_cuda_compiler_working=false is_gpu_accessible=false

    # # Verifying Drivers
    _print_info "Verifying NVIDIA driver..."
    if [ "${DEVICE_ENV}" = "LINUX" ]; then
        if command -v lspci >/dev/null 2>&1; then
            local nvidia_hw
            nvidia_hw=$(lspci | grep -i nvidia || true)
        else
            sudo apt update
            sudo apt install -y pciutils
            local nvidia_hw
            nvidia_hw=$(lspci | grep -i nvidia || true)
        fi

        if [ -z "${nvidia_hw}" ]; then
            if command -v nvidia-smi >/dev/null 2>&1; then
                _print_info "NVIDIA driver is installed on Linux."
            else
                _print_info "NVIDIA driver not found on Linux, installing drivers..."
                sudo apt install -y ubuntu-drivers-common || true
                if command -v ubuntu-drivers >/dev/null 2>&1; then
                    ubuntu-drivers devices || true
                    local driver_lst
                    driver_lst=$(ubuntu-drivers list 2>/dev/null | tail -1)
                    if [ -n "${driver_lst}" ]; then
                        info "Installing recommended driver: ${driver_lst}"
                        if sudo apt install -y "${driver_lst}"; then
                            _print_info "Drivers installed on Linux successfully."
                        else
                            abort_installation=true
                            _print_error "Error occured while installing drivers on Linux, CUDA installation aborted."
                        fi
                    else
                        abort_installation=true
                        _print_error "Unable to determine drivers on Linux for installation, CUDA installation aborted."
                    fi
                else
                    abort_installation=true
                    _print_error "Failed to install ubuntu drivers on Linux, CUDA installation aborted."
                fi
            fi
        else
            abort_installation=true
            _print_error "CUDA installation aborted, hardware type is unknown on Linux."
        fi
    elif [ "$DEVICE_ENV" = "WSL" ]; then
        if ! command -v nvidia-smi &> /dev/null; then
            abort_installation=true
            _print_note "nvidia-smi is not available on WSL..."
            _print_note " > Verify if nvidia-smi is available on windows powershell."
            _print_error "Unable to detect NVIDIA on WSL, CUDA installation aborted."
        else
            _print_info "NVIDIA driver detected on WSL."
        fi
    else
        abort_installation=true
        _print_error "CUDA installation aborted, unknown system environment."
    fi

    # # Selecting CUDA version
    local cuda_ver="" glibc_ver ver
    if ! ${abort_installation}; then
        _print_info "Selecting CUDA version..."
        glibc_ver=$(getconf GNU_LIBC_VERSION | awk '{print $2}')
        for ver in "${CUDA_VER_LST[@]}"; do
            # Skip CUDA versions below 13.2 when glibc is 2.42 or later.
            if dpkg --compare-versions "${glibc_ver}" ge "2.42" && dpkg --compare-versions "${ver}" lt "13.2"; then
                _print_note "CUDA ${ver} is not compatible with glibc ${glibc_ver}, skipping."
                continue
            fi
            cuda_ver="${ver}"
            break
        done

        if [ -z "${cuda_ver}" ]; then
            abort_installation=true
            _print_error "No CUDA version in the list is compatible with glibc ${glibc_ver}, CUDA installation aborted."
        else
            _print_info "CUDA ${cuda_ver} selected for glibc ${glibc_ver}."
        fi
    fi

    if ! ${abort_installation}; then
        _print_info "Inserting CUDA repository..."
        
        wget -q -O /tmp/cuda-keyring.deb \
            https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-keyring_1.1-1_all.deb
        
        sudo dpkg -i /tmp/cuda-keyring.deb
        sudo apt update
        
        _print_info "Installing CUDA Toolkit..."
        if sudo apt-get install -y "cuda-toolkit-${cuda_ver}"; then
            _print_info "CUDA Toolkit installed successfully."
            if ! grep -q "/usr/local/cuda/bin" "${HOME}/.bashrc"; then
                cat >> "${HOME}/.bashrc" <<'EOF'
# CUDA
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

EOF
                _print_info "CUDA path has been added into bashrc."
            else
                _print_note "CUDA path exist in bashrc, skipping adding of path."
            fi
            # Apply CUDA paths to the current session for the verification steps.
            export PATH=/usr/local/cuda/bin:$PATH
            export LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH:-}"
            is_cuda_success=true
        else
            _print_error "Failed to install CUDA Toolkit."
        fi
    fi

    if ${is_cuda_success}; then
        _print_info "Verifying CUDA Compiler"
        if command -v nvcc >/dev/null 2>&1; then
            nvcc --version
            _print_info "CUDA compiler detected."
            is_cuda_compiler_working=true
        else
            _print_error "CUDA compiler not found."
        fi

        _print_info "Verifying GPU access."
        if command -v nvidia-smi >/dev/null 2>&1; then
            _print_info "Nvidia driver is accessible."
            is_gpu_accessible=true
        else
            _print_error "nvidia-smi missing."
        fi

        if ${is_cuda_compiler_working} && ${is_gpu_accessible}; then
            _print_info "Testing CUDA environment..."
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
                    _print_info "CUDA execution successful."
                else
                    _print_error "CUDA test execution failed."
                fi
            else
                _print_error "Failed to compile cuda object for test."
            fi
            sudo rm -R "${SCRIPT_DIR}/cuda_test"
        else
            _print_error "CUDA verification failed."
        fi
    fi
}