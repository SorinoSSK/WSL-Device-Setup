_sudo_check()
{    
    if ! sudo -v; then
        _print_error "sudo authentication failed"
        exit 1
    else
        return 0
    fi
}

_confirm()
{
    local prompt="${1:-}"
    read -p "${prompt} Y/[N]: " response
    [[ "${response}" =~ ^([yY]|[yY][eE][sS])$ ]]
}

_array_empty_check()
{
    local array_name="${1:-}"
    
    if ! declare -p "${array_name}" 2>/dev/null | grep -q 'declare -a'; then
        _print_info "Invalid array variable, ${array_name}" >&2
        return 1
    else
        declare -n array_ref="${array_name}"
        if [ ${#array_ref[@]} -eq 0 ]; then
            _print_info "Empty array, ${array_name}" >&2
            return 1
        else
            local element
            for element in "${array_ref[@]}"; do
                if [ -z "$element" ]; then
                    _print_info "Empty element in array ${array_name}" >&2
                    return 1
                fi
            done
        fi
    fi
    return 0
}