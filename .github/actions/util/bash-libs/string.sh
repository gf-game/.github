# Usage: slug=$(slugify VAR_NAME)
# Prints $VAR_NAME lowercased, with each run of characters outside [a-z0-9] replaced by '-'
# and leading/trailing '-' trimmed. Fails if the result is empty.
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

    printf '%s' "${slug}"
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
