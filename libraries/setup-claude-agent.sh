_install_claude()
{
    echo "========================================"
    echo " > Claude Installation"
    echo "========================================"

    curl -fsSL https://claude.ai/install.sh | bash

    local script_dir="${1:-}"
    cp -R "${script_dir}/${AGENTS_DIR}" ~/.claude/agents
}