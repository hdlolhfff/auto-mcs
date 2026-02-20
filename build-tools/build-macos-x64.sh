#!/bin/bash

# Build auto-mcs for x64 macOS (Intel) from ARM Mac
# This script uses Rosetta 2 to cross-compile

set -e

# Create CI 'build-data.json'
if [ "${CI:-}" = "true" ]; then
    
    BRANCH=""
    BUILD=""
    COMMIT=""
    REPO=""

    # Parse required parameters, ignore everything else
    while [ $# -gt 0 ]; do
        case "$1" in
            --branch)
                [ $# -ge 2 ] || { echo "missing value for --branch" >&2; break; }
                BRANCH=$2; shift 2 ;;
            --build)
                [ $# -ge 2 ] || { echo "missing value for --build" >&2; break; }
                BUILD=$2; shift 2 ;;
            --commit)
                [ $# -ge 2 ] || { echo "missing value for --commit" >&2; break; }
                COMMIT=$2; shift 2 ;;
            --repo)
                [ $# -ge 2 ] || { echo "missing value for --repo" >&2; break; }
                REPO=$2; shift 2 ;;
            *) shift ;;
        esac
    done

    write_build_json() {

        branch=$1
        build=$2
        commit=$3
        repo=$4

        # Don't create the file if parameters are missing
        if [ -z "$branch" ] || [ -z "$build" ] || [ -z "$commit" ] || [ -z "$repo" ]; then
        	echo "Skipping 'build-data.json'"
            return 0
        fi

        type=development
        [ "$branch" = "main" ] && type=release

        # Path of this script when executed directly
        here=$(cd "$(dirname "$0")" && pwd)
        repo_root=$(cd "$here/.." && pwd)
        out="$repo_root/source/build-data.json"

        # Ensure directory exists
        mkdir -p "$(dirname "$out")" || return 0

        # Use %s for version to avoid numeric-only constraint
        if printf '{"type":"%s","version":"%s","branch":"%s","commit":"%s","repo":"%s"}' \
            "$type" "$build" "$branch" "$commit" "$repo" >"$out"
        then
            echo "Wrote $out"
        fi
    }

    write_build_json "$BRANCH" "$BUILD" "$COMMIT" "$REPO"
fi

# Global variables
shopt -s expand_aliases

# Intel Homebrew paths (installed under Rosetta)
intel_brew="/usr/local/bin/brew"
python="/usr/local/bin/python3.12"
venv_path="./venv-x64"
spec_file="auto-mcs.macos-x64.spec"

# Overwrite current directory
cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
current=$( pwd )

error ()
{
    { printf '\E[31m'; echo "$@"; printf '\E[0m'; } >&2
    cd $current
    exit 1
}

info ()
{
    printf '\E[34m'; echo "$@"; printf '\E[0m';
}

# Check if running on ARM Mac
arch_check=$(uname -m)
if [ "$arch_check" != "arm64" ]; then
    error "This script is designed to cross-compile from ARM Mac to x64. Use build-macos.sh instead."
fi

# Check if Rosetta 2 is installed
if ! /usr/bin/pgrep -q oahd; then
    info "Installing Rosetta 2..."
    softwareupdate --install-rosetta --agree-to-license
fi

# Check if Intel Homebrew is installed
if ! [ -f "$intel_brew" ]; then
    info "Installing Intel Homebrew (x86_64)..."
    arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! [ -f "$intel_brew" ]; then
    error "Failed to install Intel Homebrew at $intel_brew"
fi

# Check for Python 3.12 (Intel)
version=$( arch -x86_64 $python --version 2>/dev/null ) || version=""
if [ -z "$version" ]; then
    info "Installing Python 3.12 (x86_64) via Intel Homebrew..."
    arch -x86_64 $intel_brew install python@3.12 python-tk@3.12
    
    version=$( arch -x86_64 $python --version 2>/dev/null ) || version=""
    if [ -z "$version" ]; then
        error "Failed to install Python 3.12 (x86_64)"
    fi
fi

info "Detected $version (x86_64)"

# Create x64 virtual environment
cd $current
if ! [ -d $venv_path ]; then
    info "Creating x86_64 virtual environment..."
    arch -x86_64 $python -m venv $venv_path
else
    info "Detected existing x86_64 virtual environment"
fi

# Install packages
info "Installing packages..."
source $venv_path/bin/activate

arch -x86_64 pip install --upgrade pip setuptools wheel
arch -x86_64 pip install --upgrade -r ./reqs-macos.txt

# Fix pkg_resources issue with newer Python - upgrade altgraph and pyinstaller
arch -x86_64 pip install --upgrade altgraph pyinstaller

# Remove Kivy icons to prevent dock flickering
rm -rf $venv_path/lib/python3.12/site-packages/kivy/data/logo/*

# Create x64-specific spec file with target_arch
info "Creating x64 spec file..."
sed 's/target_arch = None/target_arch = "x86_64"/' auto-mcs.macos.spec > $spec_file

# Build
info "Compiling auto-mcs for x86_64..."
export KIVY_AUDIO=ffpyplayer
cd $current
cp $spec_file ../source
cd ../source
rm -rf build/
rm -rf dist/
arch -x86_64 pyinstaller "$spec_file" --clean --log-level INFO
cd $current
rm -rf ../source/$spec_file
rm -rf $spec_file
rm -rf ../source/dist/auto-mcs
rm -rf ./dist-x64
mv -f ../source/dist ./dist-x64
deactivate

# Check if compiled
if ! [ -d $current/dist-x64/auto-mcs.app ]; then
    error "[FAIL] Something went wrong during compilation"
else
    chmod +x $current/dist-x64/auto-mcs.app/Contents/MacOS/auto-mcs
    
    # Verify architecture
    app_arch=$(file $current/dist-x64/auto-mcs.app/Contents/MacOS/auto-mcs | grep -o "x86_64" || true)
    if [ -z "$app_arch" ]; then
        error "[FAIL] Binary is not x86_64 architecture"
    fi
    
    echo "[SUCCESS] Compiled x86_64 binary: \"$current/dist-x64/auto-mcs.app\""
fi
