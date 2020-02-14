#!/bin/bash

set -o xtrace

/etc/init.d/redis-server start
/etc/init.d/postgresql start

runuser -l openvas -c 'greenbone-nvt-sync'
openvas -u

ospd-openvas --log-level=DEBUG -l /usr/local/var/log/ospd-openvas.log 
( tail -f -n0 /usr/local/var/log/ospd-openvas.log & ) | grep -q "Finish loading up vts"

gvmd --osp-vt-update=/var/run/ospd/ospd.sock --unix-socket /var/run/gvmd.sock --listen-owner=openvas 

tail -f /usr/local/var/log/gvm/gvmd.log &
( tail -f -n0 /usr/local/var/log/gvm/gvmd.log & ) | grep -q "done"

gvmd --create-user openvas --password openvas

gvmd --get-scanners | grep "OpenVAS Default" | cut -d " " -f 1
gvmd --modify-scanner=$(gvmd --get-scanners | grep "OpenVAS Default" | cut -d " " -f 1) --scanner-host=/var/run/ospd/ospd.sock
gvmd --verify-scanner=$(gvmd --get-scanners | grep "OpenVAS Default" | cut -d " " -f 1)                                       

pkill ospd-openvas
pkill gvmd
rm -f /var/run/ospd.pid
rm -f /usr/local/var/run/gvmd.pid