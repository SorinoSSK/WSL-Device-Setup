_install_claude()
{
    echo "========================================"
    echo " > Claude Installation"
    echo "========================================"

    curl -fsSL https://claude.ai/install.sh | bash

    local script_dir="${1:-}"
    cp -R "${script_dir}/${AGENTS_DIR}" ~/.claude/agents/

    if ! grep -q "\${HOME}/.local/bin:\${PATH}" "${HOME}/.bashrc"; then
        echo 'export PATH="${HOME}/.local/bin:${PATH}"' >> ~/.bashrc
        _print_info "Added claude path into bash."
    else
        _print_info "Claude path is already in bash."
    fi
}