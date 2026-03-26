#!/bin/bash

# Version 2.1
#
# Script to add a cron job to check for, download, and install the most recent version from this git repo.
# This will auto-close signal-desktop before installing, default is to check after 5 min on reboot and every 2 days.
#
# NOTE: This client is assuming you have DNSSEC on and validating querys on your local domain/device; or that
# you are inherently trusting https://github.com and thus https://githubusercontent.com.
# #WIP: New feat. add gh attestation verifications #WIP
# Author: Shant Tchatalbachian

# Function to check for 1.1.1.1 internet connectivity
check_internet() {
    wget -q --spider https://1.1.1.1/help
    return $?
}

# Copy the script to /usr/bin/sd-updater if it doesn't exist
if [ ! -f /usr/bin/sd-updater ]; then
    # Check for internet
    if check_internet; then
        echo "Internet is available."
    else
        echo "No internet connection. Exiting."
        exit 1
    fi
    apt update && apt install -y wget cron
    wget -q -O /usr/bin/sd-updater https://raw.githubusercontent.com/0mniteck/Signal-Desktop-Reproducible/master/auto-update-cron.sh
    chmod +x /usr/bin/sd-updater
    echo "Signal-Desktop-Updater installed to /usr/bin/sd-updater."
else
    sleep 5m
    # Check for internet
    if check_internet; then
        echo "Internet is available."
    else
        echo "No internet connection. Exiting."
        exit 1
    fi
    echo "/usr/bin/sd-updater already exists, checking for update."
    wget -q -O /usr/bin/sd-updater-tmp https://raw.githubusercontent.com/0mniteck/Signal-Desktop-Reproducible/master/auto-update-cron.sh
    new_sdu_version=$(sed -n '3p' /usr/bin/sd-updater-tmp)
    sdu_version=$(sed -n '3p' /usr/bin/sd-updater)
    if [ "$new_sdu_version" != "$sdu_version" ]; then
        mv /usr/bin/sd-updater-tmp /usr/bin/sd-updater
        chmod +x /usr/bin/sd-updater
        echo "0 2 * * * root /usr/bin/sd-updater" > /etc/cron.d/sd-updater
        echo "@reboot root /usr/bin/sd-updater" >> /etc/cron.d/sd-updater
        echo "/usr/bin/sd-updater updated to $new_sdu_version"
    else
        rm -f /usr/bin/sd-updater-tmp
        echo "/usr/bin/sd-updater $sdu_version"
    fi
fi

# Function to get the current version installed
get_current_version() {
    if [ -f /usr/bin/signal-desktop ]; then
        current_version=$(apt info signal-desktop | grep Version | awk '{print $2}')
        echo "$current_version"
    else
        echo "not_installed"
    fi
}

# Function to download the latest version info
download_latest_version_info() {
    rm -f /tmp/latest-linux-arm64.yml
    wget -q -O /tmp/latest-linux-arm64.yml https://raw.githubusercontent.com/0mniteck/Signal-Desktop-Reproducible/master/builds/release/latest-linux-arm64.yml
}

# Function to extract the latest version from the downloaded file
get_latest_version() {
    latest_version=$(grep 'version:' /tmp/latest-linux-arm64.yml | awk '{print $2}')
    echo "$latest_version"
}

# Function to stop any running instances of signal-desktop
stop_running_instance() {
    pkill -f signal-desktop
}

# Function to install the new version
install_new_version() {
    rm -f /tmp/signal-desktop.deb
    wget -q -O /tmp/signal-desktop.deb https://github.com/0mniteck/Signal-Desktop-Reproducible/raw/refs/heads/master/builds/release/$(grep 'url:' /tmp/latest-linux-arm64.yml | awk '{print $3}')
    apt install -y /tmp/signal-desktop.deb
}

current_version=$(get_current_version)
download_latest_version_info
latest_version=$(get_latest_version)

# Check if an update is needed
if [ "$current_version" = "not_installed" ]; then
    echo "Signal Desktop is not installed. Installing..."
    install_new_version
    rm -f /tmp/signal-desktop.deb
    rm -f /tmp/latest-linux-arm64.yml
elif [ "$current_version" != "$latest_version" ]; then
    echo "Updating Signal Desktop from version $current_version to $latest_version"
    stop_running_instance
    install_new_version
    rm -f /tmp/signal-desktop.deb
    rm -f /tmp/latest-linux-arm64.yml
else
    echo "Signal Desktop is already up to date - version $current_version"
    rm -f /tmp/latest-linux-arm64.yml
fi

# Check if the cron job already exists
if [ ! -f /etc/cron.d/sd-updater ]; then
    echo "0 2 * * * root /usr/bin/sd-updater" > /etc/cron.d/sd-updater
    echo "@reboot root /usr/bin/sd-updater" >> /etc/cron.d/sd-updater
    echo "Cron job added."
else
    echo "Cron job already exists."
fi
