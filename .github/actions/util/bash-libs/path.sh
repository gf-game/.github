# Usage: dir=$(validate_abs_dir_path VAR_NAME)
# Fails unless $VAR_NAME is a safe absolute directory path; prints it with any trailing slash removed.
validate_abs_dir_path() {
    local var_name="$1"

    # Guard the indirect expansion below: an invalid name is a fatal expansion error
    # that exits the whole (non-interactive) shell instead of returning non-zero.
    local name_pattern='^[A-Za-z_][A-Za-z0-9_]*$'
    if [[ ! "${var_name}" =~ $name_pattern ]]; then
        echo "::error::validate_abs_dir_path: '${var_name}' is not a valid variable name (pass the name, not the value)" >&2
        return 1
    fi

    local dir_path="${!var_name:-}"

    if [ -z "${dir_path}" ]; then
        echo "::error::${var_name} is not set" >&2
        return 1
    fi

    local pattern='^/[A-Za-z0-9._/-]*$'
    if [[ ! "${dir_path}" =~ $pattern ]]; then
        echo "::error::absolute directory path (${var_name}='${dir_path}')"\
             "doesn't match the pattern ${pattern}"\
             >&2
        return 1
    fi

    if [[ "${dir_path}" =~ (^|/)\.\.?(/|$) ]]; then
        echo "::error::absolute directory path (${var_name}='${dir_path}')"\
             "contains a '.' or '..' segment"\
             >&2
        return 1
    fi

    if [[ "${dir_path}" == *//* ]]; then
        echo "::error::absolute directory path (${var_name}='${dir_path}')"\
             "contains '//'"\
             >&2
        return 1
    fi

    # Strip a trailing slash (but keep "/" as-is)
    if [ "${dir_path}" != "/" ]; then
        dir_path="${dir_path%/}"
    fi

    printf '%s' "${dir_path}"
}

# Usage: url=$(validate_http_url VAR_NAME)
# Fails unless $VAR_NAME is a valid http(s) url; prints it with any trailing slash removed.
validate_http_url() {
    local var_name="$1"

    # Guard the indirect expansion below: an invalid name is a fatal expansion error
    # that exits the whole (non-interactive) shell instead of returning non-zero.
    local name_pattern='^[A-Za-z_][A-Za-z0-9_]*$'
    if [[ ! "${var_name}" =~ $name_pattern ]]; then
        echo "::error::validate_http_url: '${var_name}' is not a valid variable name (pass the name, not the value)" >&2
        return 1
    fi

    local url="${!var_name:-}"

    if [ -z "${url}" ]; then
        echo "::error::${var_name} is not set" >&2
        return 1
    fi

    # scheme://host[:port][/path][?query][#fragment]
    # - host is a DNS name (or IPv4) whose labels are non-empty and don't start/end with '-'
    # - userinfo ('user:pass@') isn't allowed before the host
    # - path/query/fragment are limited to RFC 3986 characters (minus the single quote)
    local label='[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?'
    local pattern='^https?://'"${label}"'(\.'"${label}"')*(:[0-9]{1,5})?([/?#][A-Za-z0-9._~:/?#@!$&()*+,;=%-]*)?$'
    if [[ ! "${url}" =~ $pattern ]]; then
        echo "::error::http(s) url (${var_name}='${url}')"\
             "doesn't match the pattern ${pattern}"\
             >&2
        return 1
    fi

    # Pull the port (if any) out of the authority, i.e. what sits between '://' and the first '/', '?' or '#'
    local authority="${url#*://}"
    authority="${authority%%[/?#]*}"
    if [[ "${authority}" == *:* ]]; then
        local port="${authority##*:}"
        if (( 10#${port} < 1 || 10#${port} > 65535 )); then
            echo "::error::http(s) url (${var_name}='${url}')"\
                 "has an out-of-range port ${port}"\
                 >&2
            return 1
        fi
    fi

    # Every '%' must start a percent-encoded octet
    local bad_percent_pattern='%([^0-9A-Fa-f]|.[^0-9A-Fa-f]|.?$)'
    if [[ "${url}" =~ $bad_percent_pattern ]]; then
        echo "::error::http(s) url (${var_name}='${url}')"\
             "contains a malformed percent-encoding"\
             >&2
        return 1
    fi

    # Strip a trailing slash
    url="${url%/}"

    printf '%s' "${url}"
}
