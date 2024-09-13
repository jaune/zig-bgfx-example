#!/usr/bin/env bash

# See https://github.com/tigerbeetle/tigerbeetle/blob/main/bootstrap.sh
# See https://bun.sh/install

# Since this script potentially updates itself, putting the script in
# braces forces sh to parse the entire script before executing it so
# it isn't concurrently parsing a script that is changing on disk.
# https://stackoverflow.com/a/2358432/1507139
{
    set -e

    error() {
        echo -e "error:" "$@" >&2
        exit 1
    }

    download_bin() {
        bin_name=$1
        bin_dir=$2
        download_path=$3
        download_url=$4
        strip_components=$5

        echo "Downloading $bin_name..."

        curl --fail --location --progress-bar --output "$download_path" "$download_url" ||
            error "Failed to download zig from \"$download_url\""

        if [[ ! -d $bin_dir ]]; then
            mkdir -p "$bin_dir" ||
                error "Failed to create directory \"$bin_dir\""
        fi

        echo "Extracting zig..."

        tar -Jxf $download_path --strip-components $strip_components -C $bin_dir ||
            error "Failed to uncompress $bin_name"
    }

    script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

    version="$(cat ./.zig-version | tr -d ' ')"


    case $(uname -ms) in
    'Darwin x86_64')
        target_arch=x86_64
        target_os=macos
        ;;
    'Darwin arm64')
        target_arch=aarch64
        target_os=macos
        ;;
    'Linux aarch64' | 'Linux arm64')
        target_arch=aarch64
        target_os=linux
        ;;
    'Linux x86_64' | *)
        target_arch=x86_64
        target_os=linux
        ;;
    esac

    download_dir="$script_dir/.bin/.download"

    if [[ ! -d $download_dir ]]; then
        mkdir -p "$download_dir" ||
            error "Failed to create directory \"$download_dir\""
    fi

    ###########################################################################
    ## ZIG
    ###########################################################################
    # zig_download_url="https://ziglang.org/builds/zig-$target-$version.tar.xz"
    zig_target="$target_os-$target_arch"
    zig_download_url="https://ziglang.org/download/$version/zig-$zig_target-$version.tar.xz"
    zig_download_path="$download_dir/zig-$zig_target-$version.tar.xz"
    zig_dir="$script_dir/.bin/zig"
    zig_exe="$zig_dir/zig"

    if [[ ! -f $zig_exe ]]; then
        download_bin "zig" $zig_dir $zig_download_path $zig_download_url 1
    fi

    zig_version=`exec $zig_exe version`

    if [[ ! $zig_version == $version ]]; then
        error "Invalid zig version. expected $version, given $zig_version"
    fi

    echo "zig $zig_version"

    ###########################################################################
    ## ZLS
    ###########################################################################


    if [[ $version == "0.11.0" ]]; then
        zls_download_ext="gz"    
        zls_strip_components=1
        zls_relative_exe="bin/zls"
    else
        zls_download_ext="xz"
        zls_strip_components=0
        zls_relative_exe="zls"
    fi

    zls_dir="$script_dir/.bin/zls"
    zls_exe="$zls_dir/$zls_relative_exe"
    zls_workspace_exe=".bin/zls/$zls_relative_exe"

    zls_target="$target_arch-$target_os"
    zls_download_url="https://github.com/zigtools/zls/releases/download/$version/zls-$zls_target.tar.$zls_download_ext"
    zls_download_path="$download_dir/zls-$zls_target.tar.$zls_download_ext"

    if [[ ! -f $zls_exe ]]; then
        download_bin "zls" $zls_dir $zls_download_path $zls_download_url $zls_strip_components
    fi

    chmod +x $zls_exe

    zls_version=`exec $zls_exe --version`

    if [[ ! $zls_version == $version ]]; then
        error "Invalid zig version. expected $version, given $zls_version"
    fi

    echo "zls $zls_version"

    ###########################################################################
    ## .vscode/settings.json
    ###########################################################################

    vscode_dir="$script_dir/.vscode"

    if [[ ! -d $vscode_dir ]]; then
        mkdir -p "$vscode_dir" ||
            error "Failed to create directory \"$vscode_dir\""
    fi

    cat <<EOM >"$vscode_dir//settings.json"
{
    "zig.path": "\${workspaceFolder}/.bin/zig/zig",
    "terminal.integrated.env.osx": {
      "PATH": "\${workspaceFolder}/.bin/zig/:\$PATH"
    },
    "git.ignoreLimitWarning": true,
    "zig.zls.path": "\${workspaceFolder}/$zls_workspace_exe",
    "cSpell.ignoreWords": [
        "rdparty"
    ],
    "cSpell.words": [
        "usingnamespace"
    ]
}
EOM

    ###########################################################################
    ## Cleanup
    ###########################################################################
    rm -fr $download_dir ||
        error "Failed to remove $download_dir"

    # See https://stackoverflow.com/a/2358432/1507139.
    exit 0;
}
