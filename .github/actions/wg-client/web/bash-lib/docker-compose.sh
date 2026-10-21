# Source the libraries this file depends on, resolved relative to this file so it works from any cwd.
_docker_compose_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_docker_compose_lib_dir}/../../../util/bash-libs/string.sh"
unset _docker_compose_lib_dir

# Usage: get_project_name <repo-slug> <env-slug> <branch-slug>
# Returns name of the docker compose project for the given <repo-slug>, <env-slug> and <branch-slug>.
# The name is assembled in the pattern "<repo_slug>_<env_slug>_<branch_slug>_web"
# Fails if the given <repo-slug>, <env-slug> or <branch-slug> isn't valid slug.
get_project_name() {
    local repo_slug="$1"
    validate_slug repo_slug || return 1

    local env_slug="$2"
    validate_slug env_slug || return 1

    local branch_slug="$3"
    validate_slug branch_slug || return 1

    printf '%s' "${repo_slug}_${env_slug}_${branch_slug}_web"
}