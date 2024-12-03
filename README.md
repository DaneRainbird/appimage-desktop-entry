### AppImage Desktop Entry
My personal fork of a bash script that creates desktop entry for an .AppImage
This fork adds the ability for a user to provide their own icon image in the case that the AppImage does not contain one, which is common with hobbyist programs.

## Usage

Create desktop entry:

    ./appimage-desktop-entry.sh /path/to/Example.AppImage


Remove desktop entry:

    ./appimage-desktop-entry.sh /path/to/Example.AppImage --remove
