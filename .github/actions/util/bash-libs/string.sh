# Usage: slug=$(slugify VAR_NAME)
# Prints $VAR_NAME lowercased, with each run of characters outside [a-z0-9] replaced by '-'
# and leading/trailing '-' trimmed. If that changed the value, '-<hash>' is appended, where <hash>
# is 6 base36 chars derived from the original value's md5 digest, so different inputs don't
# produce the same slug. Fails if the slugified part is empty.
slugify() {
    local var_name="$1"

    # Guard the indirect expansion below: an invalid name is a fatal expansion error
    # that exits the whole (non-interactive) shell instead of returning non-zero.
    local name_pattern='^[A-Za-z_][A-Za-z0-9_]*$'
    if [[ ! "${var_name}" =~ $name_pattern ]]; then
        echo "::error::slugify: '${var_name}' is not a valid variable name (pass the name, not the value)" >&2
        return 1
    fi

    local value="${!var_name:-}"

    local slug
    slug="$(printf '%s' "${value}" | tr '[:upper:]\n' '[:lower:]-' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
    if [ -z "${slug}" ]; then
        echo "::error::${var_name}='${value}' produced an empty slug" >&2
        return 1
    fi

    # A value that is already a slug can't collide with another, so only lossy
    # conversions get the hash suffix that tells them apart.
    if [ "${slug}" != "${value}" ]; then
        local md5 n i hash='' digits='0123456789abcdefghijklmnopqrstuvwxyz'
        md5="$(printf '%s' "${value}" | md5sum)" || return 1
        # Encode the first 32 bits of the digest as 6 base36 digits (~31 bits).
        n=$((16#${md5:0:8}))
        for ((i = 0; i < 6; i++)); do
            hash="${digits:n % 36:1}${hash}"
            n=$((n / 36))
        done
        slug="${slug}-${hash}"
    fi

    printf '%s' "${slug}"
}

# Usage: validate_slug VAR_NAME
# Validate $VAR_NAME is a string containing non-empty runs of lowercase letters/digits separated by single hyphens.
validate_slug() {
    local var_name="$1"

    # Guard the indirect expansion below: an invalid name is a fatal expansion error
    # that exits the whole (non-interactive) shell instead of returning non-zero.
    local name_pattern='^[A-Za-z_][A-Za-z0-9_]*$'
    if [[ ! "${var_name}" =~ $name_pattern ]]; then
        echo "::error::validate_slug: '${var_name}' is not a valid variable name (pass the name, not the value)" >&2
        return 1
    fi

    local value="${!var_name:-}"

    local pattern='^[a-z0-9]+(-[a-z0-9]+)*$'
    if [[ ! "${value}" =~ $pattern ]]; then
        echo "::error::validate_slug: ${var_name}='${value}' doesn't match the pattern ${pattern}" >&2
        return 1
    fi
}

# Usage: value=$(trim_non_empty VAR_NAME)
# Prints $VAR_NAME with leading/trailing whitespace trimmed. Fails if the result is empty.
trim_non_empty() {
    local var_name="$1"

    # Guard the indirect expansion below: an invalid name is a fatal expansion error
    # that exits the whole (non-interactive) shell instead of returning non-zero.
    local name_pattern='^[A-Za-z_][A-Za-z0-9_]*$'
    if [[ ! "${var_name}" =~ $name_pattern ]]; then
        echo "::error::trim_non_empty: '${var_name}' is not a valid variable name (pass the name, not the value)" >&2
        return 1
    fi

    local value="${!var_name:-}"
    # Trim leading, then trailing whitespace.
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    if [ -z "${value}" ]; then
        echo "::error::trim_non_empty: ${var_name} is empty or whitespace-only" >&2
        return 1
    fi

    printf '%s' "${value}"
}

# Usage: validate_json_object VAR_NAME
# Validate $VAR_NAME is a json object.
validate_json_object() {
    local var_name="$1"

    # Guard the indirect expansion below: an invalid name is a fatal expansion error
    # that exits the whole (non-interactive) shell instead of returning non-zero.
    local name_pattern='^[A-Za-z_][A-Za-z0-9_]*$'
    if [[ ! "${var_name}" =~ $name_pattern ]]; then
        echo "::error::validate_json_object: '${var_name}' is not a valid variable name (pass the name, not the value)" >&2
        return 1
    fi

    local value="${!var_name:-}"

    # Slurp the input into an array so exactly one JSON document is required:
    # empty/whitespace-only input yields [] and multiple concatenated documents yield
    # more than one element. That document must then be an object.
    if ! printf '%s' "${value}" | jq -e -s 'length == 1 and (.[0] | type == "object")' > /dev/null 2>&1; then
        echo "::error::validate_json_object: ${var_name} is not a single valid JSON object" >&2
        return 1
    fi
}

# Usage: validate_file_name VAR_NAME
# Validate $VAR_NAME is a non-empty string of only letters, digits, '.', '_' and '-',
# other than the relative path segments '.' and '..'.
validate_file_name() {
    local var_name="$1"

    # Guard the indirect expansion below: an invalid name is a fatal expansion error
    # that exits the whole (non-interactive) shell instead of returning non-zero.
    local name_pattern='^[A-Za-z_][A-Za-z0-9_]*$'
    if [[ ! "${var_name}" =~ $name_pattern ]]; then
        echo "::error::validate_file_name: '${var_name}' is not a valid variable name (pass the name, not the value)" >&2
        return 1
    fi

    local value="${!var_name:-}"

    local pattern='^[A-Za-z0-9._-]+$'
    if [[ ! "${value}" =~ $pattern ]]; then
        echo "::error::validate_file_name: ${var_name}='${value}' doesn't match the pattern ${pattern}" >&2
        return 1
    fi

    if [[ "${value}" == "." || "${value}" == ".." ]]; then
        echo "::error::validate_file_name: ${var_name}='${value}' is a relative path segment" >&2
        return 1
    fi
}
