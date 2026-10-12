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
