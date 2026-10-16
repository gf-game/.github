# Source the libraries this file depends on, resolved relative to this file so it works from any cwd.
_app_config_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_app_config_lib_dir}/../../../util/bash-libs/string.sh"
source "${_app_config_lib_dir}/../../../util/bash-libs/path.sh"
unset _app_config_lib_dir

# Usage: dir=$(make_app_config_dir "${app_config_root}" "${repo_slug}" "${branch_slug}" "${cocos_version}" "${platform}" "${app_version}")
# Creates the directory <app_config_root>/<repo_slug>/<branch_slug>/<cocos_version_slug>/<platform_slug>/<app_version_slug>
# if it's not there, and prints its path (without a trailing slash). cocos_version, platform and
# app_version are slugified; app_config_root must be a safe absolute path, and repo_slug and
# branch_slug must be valid file names. Fails if any of them is invalid or the directory can't be created.
make_app_config_dir() {
    # Assemble path of the app config directory
    local app_config_root="$1"
    app_config_root="$(validate_abs_path app_config_root)" || return 1

    local repo_slug="$2"
    validate_file_name repo_slug || return 1

    local branch_slug="$3"
    validate_file_name branch_slug || return 1

    local cocos_version="$4"
    local platform="$5"
    local app_version="$6"

    local cocos_version_slug platform_slug app_version_slug
    cocos_version_slug="$(slugify cocos_version)" || return 1
    platform_slug="$(slugify platform)" || return 1
    app_version_slug="$(slugify app_version)" || return 1

    local app_config_dir="${app_config_root}/${repo_slug}/${branch_slug}/${cocos_version_slug}/${platform_slug}/${app_version_slug}"
    app_config_dir="$(validate_abs_path app_config_dir)" || return 1

    # Create the directory, if it's not there yet.
    mkdir -p "${app_config_dir}" || return 1

    # Output the path of the directory
    printf '%s' "${app_config_dir}"
}

# Usage: path=$(get_app_config_path "${app_config_dir}" "${app_sn}")
# Prints <app_config_dir>/<app_sn_slug>.json, validated as a safe absolute path. Doesn't create the file.
# Fails if app_config_dir isn't a safe absolute path or app_sn produces an empty slug.
get_app_config_path() {
    local app_config_dir="$1"
    app_config_dir="$(validate_abs_path app_config_dir)" || return 1

    local app_sn="$2"
    local app_sn_slug
    app_sn_slug="$(slugify app_sn)" || return 1

    local app_config_path="${app_config_dir}/${app_sn_slug}.json"
    app_config_path="$(validate_abs_path app_config_path)" || return 1

    printf '%s' "${app_config_path}"
}

# Usage: temp_path=$(make_temp_app_config "${app_config_path}")
# Creates an empty temp file <dir of app_config_path>/.<file name of app_config_path>.XXXXXX (mode 600)
# and prints its path. It sits in the same directory so it can be atomically 'mv'-ed over the app config;
# the caller must remove it if that doesn't happen (e.g. via a 'trap ... EXIT').
# Fails if app_config_path isn't a safe absolute path or the file can't be created.
make_temp_app_config() {
    local app_config_path="$1"
    app_config_path="$(validate_abs_path app_config_path)" || return 1

    local temp_app_config_path
    temp_app_config_path=$(mktemp "$(dirname "$app_config_path")/.$(basename "$app_config_path").XXXXXX") || return 1

    printf '%s' "${temp_app_config_path}"
}

# Usage: path=$(make_app_config_link "${link_root}" "${app_sn}" "${target}")
# Creates <link_root> if needed and (re)points the symlink <link_root>/<app_sn_slug>.json at <target>,
# then prints the link's path. Fails if link_root or target isn't a safe absolute path,
# app_sn produces an empty slug, or the directory/link can't be created.
make_app_config_link() {
    # Assemble the path to the app config link
    local root="$1"
    root="$(validate_abs_path root)" || return 1

    local app_sn="$2"
    local app_sn_slug
    app_sn_slug="$(slugify app_sn)" || return 1

    local target="$3"
    target="$(validate_abs_path target)" || return 1

    local link_path="${root}/${app_sn_slug}.json"
    link_path=$(validate_abs_path link_path) || return 1

    # Create the root directory, if it's not there yet.
    mkdir -p "${root}" || return 1

    # Create the link under a temp name and rename it over the old one, so the link is never missing.
    # -T makes mv fail instead of moving the temp link into ${link_path} if that's a real directory.
    local temp_link="${link_path}.tmp.$$"
    ln -sfn "${target}" "${temp_link}" || return 1
    if ! mv -Tf "${temp_link}" "${link_path}"; then
        rm -f "${temp_link}"
        return 1
    fi

    # Output the link path
    printf '%s' "${link_path}"
}
