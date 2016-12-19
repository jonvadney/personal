#!/bin/bash

export SRC_DIR=${HOME}/src
export GO_TAR=go1.6.4.linux-armv6l.tar.gz

# Install pre-reqs
sudo apt-get install -y mercurial libusb-1.0-0 libusb-1.0-0-dev cmake

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
   cd ${SRC_DIR}/stratux
   make
fi

