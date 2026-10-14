# Usage: validate_semver VAR_NAME
# Fails unless $VAR_NAME is a valid semantic version (https://semver.org, e.g. 1.2.3, 1.2.3-rc.1+build.5).
# A leading 'v' (e.g. v1.2.3) is rejected.
validate_semver() {
    local var_name="$1"

    # Guard the indirect expansion below: an invalid name is a fatal expansion error
    # that exits the whole (non-interactive) shell instead of returning non-zero.
    local name_pattern='^[A-Za-z_][A-Za-z0-9_]*$'
    if [[ ! "${var_name}" =~ $name_pattern ]]; then
        echo "::error::validate_semver: '${var_name}' is not a valid variable name (pass the name, not the value)" >&2
        return 1
    fi

    local value="${!var_name:-}"

    if [ -z "${value}" ]; then
        echo "::error::${var_name} is not set" >&2
        return 1
    fi

    # The official SemVer 2.0.0 regex, rewritten as POSIX ERE (no non-capturing groups or \d).
    local num='(0|[1-9][0-9]*)'
    local pre_id='(0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*)'
    local build_id='[0-9A-Za-z-]+'
    local pattern="^${num}\.${num}\.${num}(-${pre_id}(\.${pre_id})*)?(\+${build_id}(\.${build_id})*)?$"
    if [[ ! "${value}" =~ $pattern ]]; then
        echo "::error::${var_name}='${value}' is not a valid semantic version (e.g. 1.2.3, 1.2.3-rc.1+build.5)" >&2
        return 1
    fi
}
