#!/bin/bash

# File: appimage-desktop-entry.sh
# Author: Dane Rainbird (hello@danerainbird.me)
# Original Authors: un1t (Ilya Shalyapin) & adfernandes (Andrew Fernandes) 
# Last Edited: 2024-12-03
# Purpose: Personal fork of https://github.com/un1t/appimage-desktop-entry that allows for users to provide a custom icon in cases where the AppImage does not contain an icon.

APPIMAGE_PATH=$1

# Ensure that an AppImage file was passed
if [ -z "$APPIMAGE_PATH" ]; then
    echo "Missing argument: appimage"
    exit 1
fi

if [ ! -f "$APPIMAGE_PATH" ]; then
    echo "File not found:" $APPIMAGE_PAhttps://github.com/DaneRainTH
    exit 1
fi

# Get metadata about the AppImage
APPIMAGE_FULLPATH=$(readlink -e "$APPIMAGE_PATH")
APPIMAGE_FILENAME=$(basename "$APPIMAGE_PATH")
APP_NAME="${APPIMAGE_FILENAME%.*}"

# Extract the AppImage to /tmp/ 
rm -rf /tmp/squashfs-root/
cd /tmp/
"$APPIMAGE_FULLPATH" --appimage-extract 2>/dev/null # Ensure the extract is silent
cd /tmp/squashfs-root/

# Check if there are any PNG files in the extract
FILENAMES=($(ls -d *.png 2>/dev/null))

# If there are no PNG files in the extract, then ask for a manual path
if [ ${#FILENAMES[@]} -eq 0 ]; then
    echo "No icon(s) found in the AppImage. Please provide an icon manually."
    while true; do
        read -p "Enter the full path of the icon file (must be a PNG): " MANUAL_ICON

        # Ensure a file path was provided
        if [ -z "$MANUAL_ICON" ]; then
            echo "No icon path provided. Try again, or use Control+C to exit."
            continue
        fi

        # Check if the file exists
        if [ ! -f "$MANUAL_ICON" ]; then
            echo "File not found: $MANUAL_ICON"
            continue
        fi 

        # Check file extension
        ICON_EXT="${MANUAL_ICON##*.}"
        if [[ ! "$ICON_EXT" =~ ^(png)$ ]]; then
            echo "Invalid file type. Please provide a .png file."
            continue
        fi
        
        ICON_SRC="$MANUAL_ICON"
        break
    done
else
    # If icon(s) are found, prompt user to select one of them 
    echo "Choose icon: "
    FILENAMES=($(ls -d *.png))
    i=1
    for filename in ${FILENAMES[*]}
    do
        printf " %d) %s\n" $i  $filename
        i=$(expr $i + 1)
    done
    read SELECTED_INDEX
    ICON_SRC=${FILENAMES[$(expr $SELECTED_INDEX - 1)]}
    ICON_EXT="${ICON_SRC##*.}"
fi 

# Ensure the icons directory exists
mkdir -p "${HOME}/.local/share/icons"

# Copy the icon
ICON_DST="${HOME}/.local/share/icons/$APP_NAME.$ICON_EXT"
cp "$ICON_SRC" "$ICON_DST"
echo "Icon copied to $ICON_DST"

# Create a .desktop file 
DESKTOP_ENTRY_PATH="${HOME}/.local/share/applications/$APP_NAME.desktop"

APPIMAGE_FULLPATH_ESC_SPACES="${APPIMAGE_FULLPATH// /\\ }"

cat <<EOT > "$DESKTOP_ENTRY_PATH"
[Desktop Entry]
Name=$APP_NAME
Exec="$APPIMAGE_FULLPATH"
Icon=$ICON_DST
Type=Application
Terminal=false
EOT

echo "Created a .desktop entry for ${APP_NAME}";

# Update the desktop database to ensure changes are written properly
update-desktop-database ~/.local/share/applications

echo "Updated the desktop database"

# Optional arg - remove an existing .desktop entry
if [ "$2" == "--remove" ]; then
    rm $ICON_DST
    rm $DESKTOP_ENTRY_PATH
    echo "Removed the .desktop entry for ${APP_NAME}"
fi
