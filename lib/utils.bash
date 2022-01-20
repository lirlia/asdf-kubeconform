#!/usr/bin/env bash

set -euo pipefail
set -x

# TODO: Ensure this is the correct GitHub homepage where releases can be downloaded for <YOUR TOOL>.
GH_REPO="https://github.com/yannh/kubeconform"
TOOL_NAME="kubeconform"
TOOL_TEST="kubeconform"

fail() {
  echo -e "asdf-$TOOL_NAME: $*"
  exit 1
}

curl_opts=(-fsSL)

# NOTE: You might want to remove this if <YOUR TOOL> is not hosted on GitHub releases.
if [ -n "${GITHUB_API_TOKEN:-}" ]; then
  curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
  git ls-remote --tags --refs "$GH_REPO" |
    grep -o 'refs/tags/.*' | cut -d/ -f3- |
    sed 's/^v//' # NOTE: You might want to adapt this sed to remove non-version strings from tags
}

list_all_versions() {
  # TODO: Adapt this. By default we simply list the tag names from GitHub releases.
  # Change this function if <YOUR TOOL> has other means of determining installable versions.
  list_github_tags
}

download_release() {
  local version filename url
  version="$1"
  filename="$2"

  local url=$(get_download_url $version)

  echo "* Downloading $TOOL_NAME release $version..."
  wget --quiet "$url" -O "$filename" || fail "Could not download $url"
}

get_download_url() {
  local version="$1"
  local platform="$(get_platform)"
  local arch="$(get_arch)"
  echo "$GH_REPO/releases/download/v${version}/${TOOL_NAME}-${platform}-${arch}.tar.gz"
}

get_platform() {
  uname | tr '[:upper:]' '[:lower:]'
}

get_arch() {
  uname -m
}

install_version() {
  local install_type="$1"
  local version="$2"
  local install_path="$3"

  if [ "$install_type" != "version" ]; then
    fail "asdf-$TOOL_NAME supports release installs only"
  fi

  (
    mkdir -p "$install_path"
    cp -r "$ASDF_DOWNLOAD_PATH/$TOOL_NAME" "$install_path/bin/"

    # TODO: Asert <YOUR TOOL> executable exists.
    local tool_cmd
    tool_cmd="$TOOL_TEST"
    test -x "$install_path/bin/$tool_cmd" || fail "Expected $install_path/bin/$tool_cmd to be executable."

    echo "$TOOL_NAME $version installation was successful!"
  ) || (
    # rm -rf "$install_path"
    fail "An error ocurred while installing $TOOL_NAME $version."
  )
}
