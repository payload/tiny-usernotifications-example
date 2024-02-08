#!/usr/bin/env bash
set -e

# This is a poor mans build script. It should be simple enough to get relevant information
# from this script and use it in your own build system.

# Replace with your codesign certificate name.
# For example, to create a self-signed certificate:
#   https://support.apple.com/guide/keychain-access/create-self-signed-certificates-kyca8916/mac
codesign_cert=bitflips

# vscode-clangd reads this file from the project root to get compile flags
# alternative would be to create a compile_commands.json file but that's more complicated
compile_flags_txt=`cat compile_flags.txt`

executable=bundle.app/app
clang++ -o "$executable" \
    src/main.mm \
    $compile_flags_txt \
    -Wl,-sectcreate,_\_TEXT,__info_plist,src/Info.plist \
    -framework UserNotifications \
    -framework Cocoa
codesign -s "$codesign_cert" "$executable"
./$executable
