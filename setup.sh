#!/bin/bash
clear
echo "Initiating linux setup..."
set -euo pipefail

# ============================================== #
# IMPORT REQUIRED LIBRARIES START

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

FILES_TO_IMPORT=(
"${SCRIPT_DIR}/config.ini"
"${SCRIPT_DIR}/libraries/utils/setup-utils-print.sh"
"${SCRIPT_DIR}/libraries/utils/setup-utils-function.sh"
"${SCRIPT_DIR}/libraries/setup-cuda.sh"
"${SCRIPT_DIR}/libraries/setup-common.sh"
"${SCRIPT_DIR}/libraries/setup-docker.sh"
"${SCRIPT_DIR}/libraries/setup-claude-agent.sh"
)

for FILE_TO_IMPORT in "${FILES_TO_IMPORT[@]}"; do
    if [[ ! -f "${FILE_TO_IMPORT}" ]]; then
        echo "SYSTEM ERROR: ${FILE_TO_IMPORT} not found"
        exit 1
    else
        source "${FILE_TO_IMPORT}"
    fi
done
echo

# IMPORT REQUIRED LIBRARIES END
# ============================================== #
# *
# ============================================== #
# MAIN SCRIPT START

_print_loading_message
if _confirm "Proceed with installation?"; then
    _sudo_check

    _verify_linux_env
    _update_linux
    _ssh_creation
    _install_dependencies
    _install_docker
    _install_cuda
    _install_claude "${SCRIPT_DIR}"

    echo
    _print_info "Installation Completed."
else
    _print_info "Installation Aborted."
fi

# MAIN SCRIPT END
# ============================================== #