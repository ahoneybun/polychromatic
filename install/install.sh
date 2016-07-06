#!/bin/bash
#
# Polychromatic is free software: you can redistribute it and/or modify
# it under the temms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Polychromatic is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Polychromatic. If not, see <http://www.gnu.org/licenses/>.
#
# Copyright (C) 2016 Luke Horwell <lukehorwell37+code@gmail.com>
#
############################################################################
# This script manually installs the Polychromatic and Python
# libraries.
############################################################################

# Paths
target_data="/usr/share/polychromatic"
target_bin="/usr/bin"
target_icon="/usr/share/icons"
target_apps="/usr/share/applications"
python_path=$(python3 -c "import sys; print(sys.path[-1])")
polyc_modules="$python_path/polychromatic"
razer_modules="$python_path/razer/"
locale_dir="/usr/share/locale/"
source=$(dirname "$0")/..
dependencies_apt="gir1.2-webkit2-4.0 python3-gi gir1.2-appindicator3-0.1"

# Pretty colours!
function printg() {
    echo -e "\033[92m$*\033[0m"
}

function printr() {
    echo -e "\033[91m$*\033[0m"
}

function printy() {
    echo -e "\033[93m$*\033[0m"
}

# Are we root?
if [ "$(id -u)" != "0" ]; then
    echo "To install, this script must be run as root." 1>&2
    exec sudo "$0"
    exit
fi

# Check for existing installation.
if [ -d "$target_data" ]; then
    printy "An installation already exists. Removing first..."
    $(dirname "$0")/uninstall.sh
    if [ -d "$target_data" ]; then
        echo "Uninstall failed. Aborting."
        exit 1
    fi
fi

# Install dependencies on Ubuntu/Debian
function get_distro() {
    . /etc/os-release
    echo "$ID"
}

distro=`get_distro`
if [ "$distro" == "debian" ] || [ "$distro" == "ubuntu" ]; then
    printg "Installing dependencies...\n"
    sudo apt install $dependencies_apt
    echo -e ''
else
    echo "**************************************************"
    printy "Dependencies cannot be automatically installed on this distro."
    echo "Please see the README before using the application."
    echo "**************************************************"
fi

# Check if the Razer Python modules are present.
printy "Checking if Razer modules are present..."
if [ ! -d "$razer_modules" ]; then
    echo "**************************************************"
    printr "The razer-chroma-drivers Python modules are missing!"
    echo -e "Please install them from \033[93mhttp://pez2001.github.io/razer_chroma_drivers/\033[0m"
    echo -e "They are expected to be installed here: \033[93m$razer_modules\033[0m"
    echo "**************************************************"
    read -p "Continue anyway? [y] " action
    if [ ! "$action" == 'y' ]; then
        printr "Polychromatic was not installed."
        exit 1
    fi
fi

# Create directories
printg "Creating new directories..."
mkdir "$target_data"
mkdir "$polyc_modules"

# Copy bin files.
printg "Copying to $target_bin..."
cp "$source/polychromatic-controller" "$target_bin/"
cp "$source/polychromatic-tray-applet" "$target_bin/"
chmod +x "$target_bin/polychromatic-controller"
chmod +x "$target_bin/polychromatic-tray-applet"

# Copy data files.
printg "Copying to $target_data..."
cp -r "$source/data/"* "$target_data/"

# Copy Python modules
printg "Copying to $polyc_modules..."
cp -r "$source/pylib/"* "$polyc_modules/"

# Copy icons
printg "Copying to $target_icon..."
cp "$source/install/hicolor/scalable/apps/polychromatic.svg" "$target_icon/hicolor/scalable/apps/polychromatic.svg"

# Copy locales
printg "Copying to $locale_dir..."
rsync -rlpt --exclude="polychromatic-controller.pot" --exclude="polychromatic-tray-applet.pot" --exclude=*.po "$source/locale/" "$locale_dir"

# Copy desktop launchers
printg "Copying to $target_apps..."
cp "$source/install/polychromatic-controller.desktop" "$target_apps/"
cp "$source/install/polychromatic-tray.desktop" "$target_apps/"

# Keep a copy of the uninstall script for manual removal later.
cp "$source/install/uninstall.sh" "$target_data/uninstall-polychromatic.sh"

# Post installation
printg "Updating icon cache..."
update-icon-caches /usr/share/icons/hicolor/

# Success!
printg "\nPolychromatic Installed!"
echo "----------------------------"
echo "To manually remove the software from your system cleanly later, run:"
printy "$target_data/uninstall-polychromatic.sh"
echo "----------------------------"
echo "To manually update, run:"
printy "$(pwd)/update.sh"
echo -e "----------------------------"
exit 0