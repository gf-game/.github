# Usage: validate_platform VAR_NAME
# Fails unless $VAR_NAME is 'web-mobile' or 'web-desktop'.
validate_platform() {
    local var_name="$1"

    # Guard the indirect expansion below: an invalid name is a fatal expansion error
    # that exits the whole (non-interactive) shell instead of returning non-zero.
    local name_pattern='^[A-Za-z_][A-Za-z0-9_]*$'
    if [[ ! "${var_name}" =~ $name_pattern ]]; then
        echo "::error::validate_platform: '${var_name}' is not a valid variable name (pass the name, not the value)" >&2
        return 1
    fi

    local platform="${!var_name:-}"

    if [ -z "${platform}" ]; then
        echo "::error::${var_name} is not set" >&2
        return 1
    fi

    case "${platform}" in
        web-mobile|web-desktop) ;;
        *)
            echo "::error::${var_name}='${platform}' is not a valid web platform (expected 'web-mobile' or 'web-desktop')" >&2
            return 1
            ;;
    esac
}
