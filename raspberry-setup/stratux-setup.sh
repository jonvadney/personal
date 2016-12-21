#!/bin/bash

export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export SRC_DIR=${HOME}/src
export GO_TAR=go1.6.4.linux-armv6l.tar.gz

# Install pre-reqs
sudo apt-get install -y mercurial libusb-1.0-0 libusb-1.0-0-dev cmake dnsmasq hostapd

mkdir -p ${SRC_DIR}

if [ ! -d "/usr/local/go" ] ; then
   cd /tmp
   wget https://storage.googleapis.com/golang/${GO_TAR}
   sudo tar -xzf ${GO_TAR} -C /usr/local
   sudo chgrp -R staff /usr/local/go

   rm ${GO_TAR}
fi

if grep -Fq "GOROOT" ${HOME}/.bashrc ; then
   echo "GOROOT/GOPATH already set"
else
   echo >> ${HOME}/.bashrc
   echo export GOROOT=/usr/local/go >> ${HOME}/.bashrc
   echo export GOPATH=${SRC_DIR}/go >> ${HOME}/.bashrc
   echo export PATH="\$PATH:\$GOROOT/bin" >> ${HOME}/.bashrc
   source ${HOME}/.bashrc
fi

if [ ! -d "${SRC_DIR}/rtl-sdr" ] ; then
   echo "Installing rtl-sdr"
   git clone git://git.osmocom.org/rtl-sdr.git ${SRC_DIR}/rtl-sdr
   cd ${SRC_DIR}/rtl-sdr
   mkdir build
   cd build
   cmake ../ -DINSTALL_UDEV_RULES=ON
   make
   sudo make install
   sudo ldconfig
fi

if [ ! -d "${SRC_DIR}/stratux" ] ; then
   echo "Installing stratux"
   git clone https://github.com/cyoung/stratux ${SRC_DIR}/stratux
   echo "Stratux source installed run the following"
   echo "   cd ${SRC_DIR}/stratux"
   echo "   make"
   echo "   sudo make install"
fi

# *****************************************
# Setup PI as access point: https://frillip.com/using-your-raspberry-pi-3-as-a-wifi-access-point-with-hostapd/
# *****************************************
if grep -Fq "denyinterfaces wlan0" /etc/dhcpcd.conf ; then
   echo "dhcpcd.conf is already set"
else
   sudo echo "" >> /etc/dhcpcd.conf
   sudo echo "denyinterfaces wlan0" >> /etc/dhcpcd.conf
fi

if [ ! -f "/etc/network/interfaces.d/wlan0" ] ; then 
   echo "Setup wlan0"
   sudo sh -c 'echo "allow-hotplug wlan0" >> /etc/network/interfaces.d/wlan0'
   sudo sh -c 'echo "iface wlan0 inet static" >> /etc/network/interfaces.d/wlan0'
   sudo sh -c 'echo "    address 172.24.1.1" >> /etc/network/interfaces.d/wlan0'
   sudo sh -c 'echo "    netmask 255.255.255.0" >> /etc/network/interfaces.d/wlan0'
   sudo sh -c 'echo "    network 172.24.1.0" >> /etc/network/interfaces.d/wlan0'
   sudo sh -c 'echo "    broadcast 172.24.1.255" >> /etc/network/interfaces.d/wlan0'

   sudo sed -i -- "/allow-hotplug wlan0/,+3d" "/etc/network/interfaces"
   sudo service dhcpcd restart

   # NOTE: This step disconnects the first wireless adapter, its assumed the user is connected to a different interface 
   sudo ifdown wlan0; sudo ifup wlan0
fi 

if grep -Fq "#DAEMON_CONF" /etc/default/hostapd ; then 
   echo "Setup /etc/default/hostapd"
   sudo sed -i -- "s/#DAEMON_CONF=\"\"/DAEMON_CONF=\"\/etc\/hostapd\/hostapd.conf\"/" /etc/default/hostapd
   sudo cp ${SCRIPT_DIR}/hostapd.conf /etc/hostapd/hostapd.conf
   sudo touch /etc/hostapd/hostapd.user
fi

# Make a copy of original but don't care about overriding after that
if [ ! -f /etc/dnsmasq.conf.orig ] ; then
   sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
fi
sudo cp ${SCRIPT_DIR}/dnsmasq.conf /etc/dnsmasq.conf

sudo sed -i -- "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/" /etc/sysctl.conf
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE  
sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT  
sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT

sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"

if grep -Fq "iptables-restore" /etc/rc.local ; then
   echo "iptables-restore already setup" 
else
   sudo sed -i -- "\$s/exit 0/iptables-restore < \/etc\/iptables.ipv4.nat\nexit 0/" /etc/rc.local
fi
