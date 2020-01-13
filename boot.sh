#!/bin/bash

/etc/init.d/postgresql start
/etc/init.d/redis-server start
# cat /usr/local/var/log/gvm/openvas.log


# gvmd --listen=127.0.0.1
# gvmd --listen=127.0.0.1 --osp-vt-update=/var/run/ospd/ospd.sock

tail -f /dev/null