#!/bin/bash

#
# install-script.sh
#
# @version    2.1 2017-08-08
# @copyright  Copyright (c) 2014-2017 Martin Sauter, martin.sauter@wirelessmoves.com
# @license    GNU General Public License v2
# @since      Since Release 1.0
#
# Installs and configures all necessary components
# for a Raspberry Pi 3 to act as a Wi-Fi access point
# WITH ITS INTERNAL WIF-FI and with backhaul over:
#
# a) Ethernet cable
# b) Wi-Fi, if a USB Wi-Fi dongle is connected that supplements
#    the Wi-Fi adapter already built into the Pi-3 that is used
#    as a Wi-Fi access point.
#
# For details see the project Wiki at:
#
#              https://github.com/martinsauter/WLAN-VPN-Pi/wiki
#
# Version History
#
# 1.0 - 1.51 - Version for the Raspberry Pi 1 and 2 that does not have
#        a built in Wi-Fi adapter. For these Pis a special hostapd 
#        executable is required and hence the script is different in
#        some respects
#
# 2.0    New version of this script for hte Raspberry Pi 3 with a
#        built-in Wi-Fi network interface that does not require
#        a special hostapd executable.
#
# 2.1    Updated script
#
##############################################################################
# IMPORTANT: This script significantly changes the network configuration
# of eth0, wlan0 and wlan1 and a fair number of network configuration files.
# ONLY USE WITH A FRESH RASPBERRY PI IMAGE FILE
##############################################################################
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU AFFERO GENERAL PUBLIC LICENSE
# License as published by the Free Software Foundation; either
# version 3 of the License, or any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU AFFERO GENERAL PUBLIC LICENSE for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with this library.  If not, see <http://www.gnu.org/licenses/>.

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root, please try again" 1>&2
   exit 1
fi

echo "#### Wi-Fi Pi Access Point and VPN Installation"
echo "###################################################"
echo ""

echo ""
echo "#################################################################"
echo " Updating all packages to the latest version and removing the"
echo " Wolfram engine as it is not needed and requires huge udpates."
echo " Also, tcpdump and htop are installed as they might be useful"
echo "#################################################################"

apt-get update
apt-get -y remove wolfram-engine
apt-get -y install htop tcpdump
apt-get -y upgrade

apt-get -y install rpi-update
rpi-update

#per default all configuration files are read only except for the owner
chmod 644 ./configuration-files/*
#script files must be executable
chmod 755 ./configuration-files/*.sh
#the openvpn directory needs exec rights so it can be opened
chmod 775 ./configuration-files/openvpn
#openvpn config files must only be read/writable for the owner
chmod 600 ./configuration-files/openvpn/*.*

cd ./configuration-files

echo ""
echo "done..."
echo ""

echo "#### Copying basic configuration for eth0, wlan0 and wlan1"
echo "###############################################################"

cp interfaces /etc/network/interfaces
cp wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf

echo ""
echo "done..."
echo ""


echo "#### Installing and configuring wlan0 as Wi-Fi AP"
echo "########################################################"

apt-get -y install hostapd

#copy access point configuration file
cp hostapd.conf /etc/hostapd/hostapd.conf

#put a modified action_wpa.sh in lace to fix wpa supplicant misbehavior with two Wi-Fi interfaces
cp action_wpa.sh /etc/wpa_supplicant/action_wpa.sh

#autostart hostapd on system startup
cp hostapd /etc/default/hostapd

#autostart sometimes doesn't work correctly, so add a start/stop wlan0 to rc.local
cp rc.local /etc/rc.local

echo ""
echo "done..."
echo ""


echo "#### Installing and configuring the DHCP server to serve wlan0"
echo "###################################################################"

apt-get -y install hostapd isc-dhcp-server
cp dhcpd.conf /etc/dhcp/dhcpd.conf
cp isc-dhcp-server /etc/default/isc-dhcp-server

echo ""
echo "###### NOTE: The failure report above is o.k., it will work after rebooting... #####"
echo ""

echo ""
echo "done..."
echo ""


echo "#### Enabling ip packet routing between interfaces"
echo "########################################################"

cp sysctl.conf /etc/sysctl.conf

echo ""
echo "done..."
echo ""

echo "### Installing and configuring Dnsmasq as a local DNS server"
echo "##############################################################"

apt-get install -y dnsmasq

cp dnsmasq.conf.no-tunnel /etc/dnsmasq.conf
cp dnsmasq.conf.no-tunnel /etc/dnsmasq.conf.no-tunnel
cp dnsmasq.conf.with-tunnel /etc/dnsmasq.conf.with-tunnel

echo ""
echo "done..."
echo ""


echo "### Installing the OpenVPN client service"
echo "###############################################"

apt-get -y install openvpn
cp ./openvpn/* /etc/openvpn

#disable openvpn client autostart
apt-get -y install chkconfig
chkconfig openvpn off

echo ""
echo "done..."
echo ""

echo "### Limiting SSH access to the Access Point Wifi network"
echo "### (192.168.55.0) in /etc/ssh/sshd_config"
echo "########################################################"

cp sshd_config /etc/ssh

echo ""
echo "done..."
echo ""

#copy VPN start and stop batch files to upper directory
cp start* /home/pi/
cp stop* /home/pi/

echo ""
echo "#####################################################"
echo "The Wi-Fi Access Point configuration is as follows:"
echo ""

cat /etc/hostapd/hostapd.conf

echo ""
echo "#####################################################" 
echo ""

echo ""
echo "#####################################################"
echo "The network configuration of the Wi-Fi AP interface"
echo "(wlan0) is as follows"
echo ""

cat /etc/network/interfaces

echo ""
echo "#####################################################" 
echo ""

echo ""
echo "#####################################################"
echo "For details to start Internet access with or without"
echo "the VPN tunnel see the project Wiki at Github at"
echo ""
echo "  https://github.com/martinsauter/WLAN-VPN-Pi/wiki"
echo ""
echo "#####################################################" 
echo ""

echo "#########################################################"
echo "### and now reboot to make the changes come into effect"
echo "#########################################################"


