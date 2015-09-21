#!/bin/bash

#########################################################################
# File Name:    deploy.sh
# Author:       D_L
# mail:         deel@d-l.top
# Created Time: 2015/9/17 13:42:48
#########################################################################

source $OPENSHIFT_CARTRIDGE_SDK_BASH


BUILT_DIR=$OPENSHIFT_TMP_DIR/nginx_built
test -d $BUILT_DIR || mkdir -p $BUILT_DIR

NGINX_DIR=$OPENSHIFT_DATA_DIR/nginx
test -d $NGINX_DIR || mkdir -p $NGINX_DIR

cd $BUILT_DIR

# pcre, zlib, openssl, sha1
wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.37.tar.bz2
wget http://zlib.net/zlib-1.2.8.tar.gz
#wget ftp://ftp.openssl.org/source/openssl-1.0.2.tar.gz
#wget http://www.tamale.net/sha1/sha1-0.2.tar.gz 
tar jxvf pcre-8.37.tar.bz2
tar xvf zlib-1.2.8.tar.gz
#tar xvf openssl-1.0.2.tar.gz
#tar xvf sha1-0.2.tar.gz

# nginx
wget http://nginx.org/download/nginx-1.9.4.tar.gz
tar zxvf nginx-1.9.4.tar.gz

# configure
cd $BUILT_DIR/nginx-1.9.4
./configure --prefix=$NGINX_DIR --with-pcre=$OPENSHIFT_TMP_DIR/nginx_built/pcre-8.37 --with-zlib=$OPENSHIFT_TMP_DIR/nginx_built/zlib-1.2.8  --with-ipv6 --with-http_stub_status_module --with-http_gzip_static_module --with-http_sub_module --with-http_ssl_module

#--with-openssl=/tmp/nginx_built/openssl-1.0.2
#--with-sha1=/tmp/nginx_built/sha1-0.2

if [ $? -ne 0 ]; then
	echo -e "\nAn error occurred. build nginx: './configure...'\n"
	exit 1
fi

make
if [ $? -ne 0 ]; then
	echo -e "\nAn error occurred. build nginx: 'make...'\n"
	exit 1
fi

make install
if [ $? -ne 0 ]; then
	echo -e "\nAn error occurred. install nginx: 'make install...'\n"
	exit 1
fi


# clean
rm -rf $BUILT_DIR

# backup - nginx.conf
cp -a $NGINX_DIR/conf/nginx.conf $NGINX_DIR/conf/nginx.conf.bak

echo -e "\nDeployment has been completed...\n"
#exit 0
