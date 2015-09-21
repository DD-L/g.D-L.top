#!/bin/bash

#########################################################################
# File Name: uninstall_nginx.sh
# Author: D_L
# mail: deel@d-l.top
# Created Time: 2015/9/21 11:22:01
#########################################################################

source $OPENSHIFT_CARTRIDGE_SDK_BASH

NGINX_DIR=$OPENSHIFT_DATA_DIR/nginx

# stop nginx
if [ -f $NGINX_DIR/logs/nginx.pid ]; then
	kill `cat $NGINX_DIR/logs/nginx.pid`
else
	if [ -z "$(ps -ef | grep nginx | grep -v grep)" ]; then
		echo "Application is already stopped"
	else
		kill `ps -ef | grep nginx | grep -v grep | awk '{ print $2 }'` > /dev/null 2>&1
	fi
fi

# rm nginx
echo "Deleting nginx..."
rm -rf $NGINX_DIR
