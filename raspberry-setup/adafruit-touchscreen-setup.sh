#!/bin/sh

curl -SLs https://apt.adafruit.com/add-pin | sudo bash
sudo apt-get install -y --force-yes raspberrypi-bootloader adafruit-pitft-helper raspberrypi-kernel
sudo adafruit-pitft-helper -t 35r
