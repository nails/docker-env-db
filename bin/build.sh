#!/usr/bin/env bash
#
# Build database images and publish them to Docker Hub.
#
#   bin/build.sh [mysql80] [mysql57]
#       Builds each directory (default: all) and pushes it with its tags:
#           mysql80 -> nails/docker-env-db:mysql-8.0, :latest  (linux/amd64 + linux/arm64)
#           mysql57 -> nails/docker-env-db:mysql-5.7           (linux/amd64 only; upstream
#                                                               mysql:5.7 has no arm64 build)
#       Works the same from an Apple Silicon Mac or an x86 machine; the
#       non-native architecture is built under emulation, so it is slower.
#
#   LOCAL=1 bin/build.sh [mysql80] [mysql57]
#       Builds for the host architecture only and loads the result into the
#       local Docker image store. Nothing is pushed. Use this to test changes.
#
# Environment:
#   BUILDER    buildx builder to use/create (default: nails-multiarch)
#
# Do not use `docker push nails/docker-env-db`: it pushes single-architecture
# images from the local store over the multi-arch tags.

set -euo pipefail

REPO="nails/docker-env-db"
BUILDER="${BUILDER:-nails-multiarch}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# directory -> "<platforms> <tag> [<tag>...]"
config_for() {
    case "$1" in
        mysql80) echo "linux/amd64,linux/arm64 mysql-8.0 latest" ;;
        mysql57) echo "linux/amd64 mysql-5.7" ;;
        *) return 1 ;;
    esac
}

DIRS=("$@")
[ ${#DIRS[@]} -gt 0 ] || DIRS=(mysql80 mysql57)

for dir in "${DIRS[@]}"; do
    if ! config_for "$dir" >/dev/null || [ ! -f "$ROOT/$dir/Dockerfile" ]; then
        echo "ERROR: unknown image directory '$dir' (expected mysql80 or mysql57)" >&2
        exit 1
    fi
done

# --------------------------------------------------------------------------
# Local, single-architecture build (no push)
# --------------------------------------------------------------------------

if [ "${LOCAL:-0}" = "1" ]; then
    for dir in "${DIRS[@]}"; do
        read -r _ tags <<<"$(config_for "$dir")"
        args=()
        for tag in $tags; do args+=(-t "$REPO:$tag"); done
        echo "==> [local] $dir -> $tags"
        docker build "${args[@]}" "$ROOT/$dir"
    done
    exit 0
fi

# --------------------------------------------------------------------------
# Multi-architecture build and push
# --------------------------------------------------------------------------

# The default "docker" driver cannot build multiple platforms into one
# manifest, so use a dedicated docker-container builder. It is created once
# and reused; it does not change the machine's default builder.
if ! docker buildx inspect "$BUILDER" >/dev/null 2>&1; then
    echo "==> Creating buildx builder '$BUILDER'"
    docker buildx create --name "$BUILDER" --driver docker-container --bootstrap
fi

for dir in "${DIRS[@]}"; do
    read -r platforms tags <<<"$(config_for "$dir")"
    args=()
    for tag in $tags; do args+=(--tag "$REPO:$tag"); done

    echo "==> [$platforms] $dir -> $tags"
    docker buildx build \
        --builder "$BUILDER" \
        --platform "$platforms" \
        --pull \
        --push \
        "${args[@]}" \
        "$ROOT/$dir"

    # Verify every tag's published manifest has every requested platform, so
    # an incomplete push fails loudly here instead of on a production server.
    for tag in $tags; do
        published=$(docker buildx imagetools inspect "$REPO:$tag" \
            | awk '/Platform:/ {print $2}' \
            | grep -v '^unknown/' \
            | sort -u \
            | paste -sd, -)
        for platform in ${platforms//,/ }; do
            case ",$published," in
                *",$platform,"*) ;;
                *)
                    echo "ERROR: $REPO:$tag is missing $platform (published: ${published:-none})" >&2
                    exit 1
                    ;;
            esac
        done
        echo "==> OK $REPO:$tag [$published]"
    done
done
