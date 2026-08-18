_print_info()
{
    input_msg="${1:-}"
    echo "SYSTEM MSG: ${input_msg}"
}

_print_error()
{
    input_msg="${1:-}"
    echo "SYSTEM ERROR: ${input_msg}"
}

_print_note()
{
    input_msg="${1:-}"
    echo "SYSTEM NOTE: ${input_msg}"
}

_print_remove()
{
    input_msg="${1:-}"
    echo "SYSTEM REMOVED: ${input_msg}"
}

_print_loading_message()
{
    echo "========================================"
    echo " Initiating Device Setup - v00.01"
    echo "========================================"
    echo " Pre-requisite:"
    echo "  > Linux Environment: Ubuntu"
    echo
    echo " Installation Procedure:"
    echo "  [01] Linux Update"
    echo "  [02] SSH Creation"
    echo "  [03] Project Root Repository Creation"
    echo "  [04] Dependencies Installation"
    echo "  [05] Docker Installation"
    echo "  [06] CUDA Installation"
    echo "========================================"
}