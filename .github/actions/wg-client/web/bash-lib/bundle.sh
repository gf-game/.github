# Source the libraries this file depends on, resolved relative to this file so it works from any cwd.
_bundle_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_bundle_lib_dir}/../../../util/bash-libs/string.sh"
source "${_bundle_lib_dir}/../../../util/bash-libs/path.sh"
unset _bundle_lib_dir

# Usage: dir=$(make_bundle_dir "${root}" "${repo_slug}" "${branch_slug}" \
#            "${cocos_version}" "${platform}" "${app_version}" "${env_slug}")
# Creates the directory
#     <root>/<repo_slug>/<branch_slug>/<cocos_version_slug>/<platform_slug>/<app_version_slug>/<env_slug>
# if it's not there, and prints its path (without a trailing slash). cocos_version, platform and
# app_version are slugified; root must be a safe absolute path, and repo_slug, branch_slug and
# env_slug must be valid file names. Fails if any of them is invalid or the directory can't be
# created.
make_bundle_dir() {
    # Assemble path of the bundle directory
    local root="$1"
    root="$(validate_abs_path root)" || return 1

    local repo_slug="$2"
    validate_file_name repo_slug || return 1

    local branch_slug="$3"
    validate_file_name branch_slug || return 1

    local cocos_version="$4"
    local platform="$5"
    local app_version="$6"
    local env_slug="$7"
    validate_file_name env_slug || return 1

    local cocos_version_slug platform_slug app_version_slug
    cocos_version_slug="$(slugify cocos_version)" || return 1
    platform_slug="$(slugify platform)" || return 1
    app_version_slug="$(slugify app_version)" || return 1

    local dir="${root}/${repo_slug}/${branch_slug}"
    dir+="/${cocos_version_slug}/${platform_slug}/${app_version_slug}/${env_slug}"
    dir="$(validate_abs_path dir)" || return 1

    # Create the directory, if it's not there yet.
    mkdir -p "${dir}" || return 1

    # Output the path of the directory
    printf '%s' "${dir}"
}

# Usage: link=$(make_bundle_dir_link "${link_root}" "${bundle_registry_sn}" "${target}")
# Creates <link_root> if needed and (re)points the symlink <link_root>/<bundle_registry_sn_slug> at
# <target>, then prints the link's path. Fails if link_root or target isn't a safe absolute path,
# bundle_registry_sn produces an empty slug, or the directory/link can't be created.
make_bundle_dir_link() {
    # Assemble path of the bundle directory link
    local root="$1"
    root="$(validate_abs_path root)" || return 1

    local registry_sn="$2" registry_sn_slug
    registry_sn_slug="$(slugify registry_sn)" || return 1

    local target="$3"
    target="$(validate_abs_path target)" || return 1

    local link="${root}/${registry_sn_slug}"
    link="$(validate_abs_path link)" || return 1

    # Create the root directory, if it's not there yet.
    mkdir -p "${root}" || return 1

    # Create the link under a temp name and rename it over the old one, so the link is never missing.
    # -T makes mv fail instead of moving the temp link into ${link} if that's a real directory.
    local temp_link="${link}.tmp.$$"
    ln -sfn "${target}" "${temp_link}" || return 1
    if ! mv -Tf "${temp_link}" "${link}"; then
        rm -f "${temp_link}"
        return 1
    fi

    # Output the path of the link
    printf '%s' "${link}"
}
