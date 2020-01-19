#!/bin/bash

/etc/init.d/postgresql start
/etc/init.d/redis-server start
# cat /usr/local/var/log/gvm/openvas.log

rm -f /var/run/ospd.pid
ospd-openvas --log-level=DEBUG -l /usr/local/var/log/ospd-openvas.log

until pg_isready; do sleep 1; done

gvmd --listen=127.0.0.1 --osp-vt-update=/var/run/ospd/ospd.sock
gvmd --osp-vt-update=/var/run/ospd/ospd.sock

tail -f /dev/null