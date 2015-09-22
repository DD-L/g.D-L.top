# 手动部署

手动部署，只是简单的配置反向代理服务器介绍，更完整的部署方案见 [自动化部署](./automated-deploy.md)

-------------------

#####在部署前，请确保你已经完成了 [准备工作](./pre-works.md)

1. 无特别说明，手动部署文档仍然以我的配置为例：

	1. app域名: http://nginx-deel.rhcloud.com/
	2. 二级openshift域名: deel
	3. app名： nginx
	3. 本地仓库文件夹： openshift_nginx

2. 一些可能有帮助的 [openshift 环境变量](https://developers.openshift.com/en/managing-environment-variables.html).

-----------------------

#### 安装nginx
	
1. ssh 到你的主机
	<pre>
	ssh xxxxxxxxxxxxxxx@nginx-deel.rhcloud.com
	</pre>
2. 下载 nginx 依赖库
	<pre>
	$ mkdir -p $OPENSHIFT_TMP_DIR/nginx_built
	$ cd $OPENSHIFT_TMP_DIR/nginx_built
	</pre>
	1. 下载pcre库, nginx的编译依赖这个库，url重写, sub_filter等功能会用这个正则表达式库。
		<pre>
		目前最新版本是 ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre2-10.20.tar.bz2

		但是最好不要下载最新的pcre2, 它配置起来有点烦人。
		选用ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.37.tar.bz2 的版本即可。

		$ cd $OPENSHIFT_TMP_DIR/nginx_built
		$ wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.37.tar.bz2
		$ tar jxvf pcre-8.37.tar.bz2
		</pre>
	2. zlib库，这个好像不必下载，openshift 云主机系统有，为了资料的完整性这里列出来:
		(后面编译我会用这个版本的zlib，而不是使用系统中的zlib库)
		<pre>
		$ cd $OPENSHIFT_TMP_DIR
		$ wget http://zlib.net/zlib-1.2.8.tar.gz
		$ tar xvf zlib-1.2.8.tar.gz
		</pre>
	3. openssl, 这可能也不必下载，openshift 云主机系统有，为了资料的完整性这里列出来：
		<pre>
		$ cd $OPENSHIFT_TMP_DIR/nginx_built
		$ wget ftp://ftp.openssl.org/source/openssl-1.0.2.tar.gz
		$ tar xvf openssl-1.0.2.tar.gz		
		</pre>
	4. sha1库 在 openssl 中有，不必重复下载.

3. 下载、编译并安装 nginx
	<pre>
	$ cd $OPENSHIFT_TMP_DIR/nginx_built
	$ wget http://nginx.org/download/nginx-1.9.4.tar.gz
	$ tar zxvf nginx-1.9.4.tar.gz
	
	$ mkdir -p $OPENSHIFT_DATA_DIR/nginx

	$ cd ./nginx-1.9.4
	$ ./configure --prefix=$OPENSHIFT_DATA_DIR/nginx --with-pcre=$OPENSHIFT_TMP_DIR/nginx_built/pcre-8.37 --with-zlib=$OPENSHIFT_TMP_DIR/nginx_built/zlib-1.2.8  --with-ipv6 --with-http_stub_status_module --with-http_gzip_static_module --with-http_sub_module --with-http_ssl_module
	
	#如果想用自己刚下载的openssl和sha1, 可以再加上
	#--with-openssl=/tmp/nginx_built/openssl-1.0.2
	#--with-openssl=/tmp/nginx_built/openssl-1.0.2
	#参数
	
	$ make
	$ make install
	
	# 清理临时文件
	$ rm -rf $OPENSHIFT_TMP_DIR/nginx_built
	# 备份配置文件
	$ cp -a $OPENSHIFT_DATA_DIR/nginx/conf/nginx.conf $OPENSHIFT_DATA_DIR/nginx/conf/nginx.conf.bak
	
	如果这期间不出错，nginx 会被安装在 $OPENSHIFT_DATA_DIR/nginx路径下。
	</pre>


#### 配置nginx, 使其能在openshift云主机上能跑起来.

重点在nginx的配置， nginx的配置文件被安放在了 $OPENSHIFT_DATA_DIR/nginx/conf/nginx.conf

1. openshift 提供给你的ip会不定时更新，这个要特别留意。
2. 在nginx.conf中，OpenShift不允许使用$OPENSHIFT_<cart-name>_IP和 $OPENSHIFT_<cart-name>_PORT

	根据[openshift 环境变量](https://developers.openshift.com/en/managing-environment-variables.html) 的描述
	>"The exact variable names depend on the type of cartridge; the value of <cart-name> is DIY, JBOSSAS, JBOSSEAP, JBOSSEWS, JENKINS, MONGODB, MYSQL, NODEJS, PERL, PHP, POSTGRESQL, PYTHON, or RUBY as appropriate."
	
	因为我之前创建的是DIY, 所以这里应该是 $OPENSHIFT_DIY_IP 和 $OPENSHIFT_DIY_PORT
		
	网上有说是 OPENSHIFT_INTERNAL_IP 和 OPENSHIFT_INTERNAL_PORT，这大概是老版本的openshift的环境变量，这个早就改了：https://developers.openshift.com/en/managing-environment-variables.html

	既然openshift不允许使用在配置文件中使用$OPENSHIFT_DIY_IP和$OPENSHIFT_DIY_PORT，那么只能采取曲线救国，配置起来需要点技巧：

3. 制作nginx.conf模板
	<pre>
	$ cd $OPENSHIFT_DATA_DIR/nginx
	$ vi conf/nginx.conf
	</pre>
	修改listen 的值：
	<pre>
	http {
		…
		server {
			listen       $OPENSHIFT_IP:$OPENSHIFT_PORT;
			server_name  localhost;
			… 
		}
		…
	}	
	</pre>
	把这个作为模板，在app启动的时候生成配置文件.
	<pre>
	$ mv $OPENSHIFT_DATA_DIR/nginx/conf/nginx.conf $OPENSHIFT_DATA_DIR/nginx/conf/nginx.conf.template
	</pre>
	$OPENSHIFT_PORT 也可以直接写成 8080, 因为[准备工作](./pre-works.md)中说过了，自己的服务器软件必须且只能绑定在$OPENSHIFT_DIY_IP:8080 上，你到云主机上echo下$OPENSHIFT_DIY_PORT正是8080。

	P.S.: 有人说有个地方需要注意, 但是我没配置，为了资料的完整，这里摘录下来：
	> 当nginx使用3xx重定向请求时，指向的是appname.rhcloud.com:8080,8080是内部监听端口，从外部请求8080端口将会超时，解决这个问题需要在nginx配置的http部分中添加port_in_redirect off;。

4. 编写start和stop脚本
	
	回到本地仓库, 在自己的PC上执行
	<pre>
	cd openshift_nginx/.openshift/action_hooks/
	</pre>
	1. start 脚本的编写
		<pre>$ vim start</pre>
		<pre>
		#!/bin/bash
		NGINX_DIR=$OPENSHIFT_DATA_DIR/nginx
		sed -e "s/`echo '$OPENSHIFT_IP:$OPENSHIFT_PORT'`/`echo $OPENSHIFT_DIY_IP:$OPENSHIFT_DIY_PORT`/" $NGINX_DIR/conf/nginx.conf.template > $NGINX_DIR/conf/nginx.conf
		nohup $NGINX_DIR/sbin/nginx |& /usr/bin/logshifter -tag diy &
		</pre>
		这样再openshift app启动时候，配置文件中的ip和端口号就是真实的数字了。
	2. stop 脚本的编写
		<pre>$ vim stop</pre>
		参考 [https://github.com/DD-L/g.D-L.top/blob/master/.openshift/action_hooks/stop](https://github.com/DD-L/g.D-L.top/blob/master/.openshift/action_hooks/stop)

5. 提交远程仓库，并运行网站

	请确保在提交stop脚本之前, 关停正在运行的ruby server, 这个操作是在 [准备工作](./pre-works.md) 中完成的。
	
	仍然在本地仓库运行
	<pre>
	$ #cd openshift_nginx # 进入本地仓库代码目录
	$ #git status # 检查改动文件
	$ git add .openshift/action_hooks/
	$ git commit -m "start nginx when starting up the app"
	$ git push
	</pre>

	push时需要网络畅通。

	如果push时遇到“remote: Stopping DIY cartridge fatal: The remote end hung up unexpectedly”的错误。

	原因是："It happens because the previous version of the stop script kills the process that handles your git push before it's finished"。

	解决办法是, ssh 到你的远程主机上执行：
	<pre>
	$ rm $OPENSHIFT_REPO_DIR/.openshift/action_hooks/stop
	</pre>
	再次回到本地重新 `git push` 即可解决。
	
6. 浏览器访问你的app地址(http://nginx-deel.rhcloud.com/), 以验证nginx 是否搭建成功.

#### 编写定时任务脚本
	
>添加定时任务是为了解决 "openshift 提供给你的ip会不定时更新" 的问题，因为它会影响上一步配置的nginx.conf。
>
>详细的方案，请在 [自动化部署](./automated-deploy.md) 方案中寻找。
>
>相关的脚本程序：
>
> 1. [https://github.com/DD-L/g.D-L.top/tree/master/.openshift/cron/hourly](https://github.com/DD-L/g.D-L.top/tree/master/.openshift/cron/hourly) 
> 2. [https://github.com/DD-L/g.D-L.top/blob/master/.openshift/action_hooks/start](https://github.com/DD-L/g.D-L.top/blob/master/.openshift/action_hooks/start)
	

#### 配置nginx, 使其在openshift云主机上成为 google search 的反向代理服务器.

ssh到你的云主机，修改你的nginx的模板配置文件。

<pre>vim $OPENSHIFT_DATA_DIR/nginx/conf/nginx.conf.template</pre>

这里假定你的网站域名是 nginx-mydomain.rhcloud.com

则模板配置文件样例如下：
<pre>
...
http {
	...
	# 不编写upstream google也行，后面可以直接 proxy_pass https://www.google.com;
	# 但这样做会可能导致google服务器频繁返回验证码.
	# google ip 列表可以通过 nslookup www.google.com 获得, 也可以自己编写C代码调用gethostbyname函数获得ip列表。
	upstream google {
		server 74.125.239.112:443 max_fails=3;
		server 74.125.239.113:443 max_fails=3;
		server 74.125.239.114:443 max_fails=3;
		server 74.125.239.115:443 max_fails=3;
		server 74.125.239.116:443 max_fails=3;
	}
	server {
		listen       $OPENSHIFT_IP:$OPENSHIFT_PORT;
		server_name  nginx-mydomain.rhcloud.com;
		location / {
			proxy_cookie_domain google.com nginx-mydomain.rhcloud.com;
			proxy_redirect https://www.google.com/ /;
			proxy_redirect http://www.google.com/ /;
			proxy_pass https://google;
			proxy_set_header Host "www.google.com";
			proxy_set_header Accept-Encoding "";
			proxy_set_header User-Agent $http_user_agent;
			proxy_set_header Accept-Language "zh-CN";
			proxy_set_header Cookie "PREF=ID=047808f19f6de346:U=0f62f33dd8549d11:FF=2:LD=zh-CN:NW=1:TM=1442566362:LM=1332142445:GM=1:SG=2:S=rE0SyJh2w1IQ-Maw";
			
			sub_filter_once off;
			sub_filter https://www.google.com http://nginx-mydomain.rhcloud.com ;
			sub_filter http://www.google.com  http://nginx-mydomain.rhcloud.com ;
			sub_filter //www.google.com  //nginx-mydomain.rhcloud.com ;
			sub_filter www.google.com nginx-mydomain.rhcloud.com ;
		}
		
		...
	}
	...
}
</pre>

保存退出， 在远程主机上用openshift工具重启你的nginx

<pre>
$ /usr/bin/gear stop
$ /usr/bin/gear start
</pre>

浏览器访问一下你的网站，以验证 google search 反向代理服务器是否搭建成功。


自此， 一个 "勉强可用的" google search 反向代理服务器就算是手动搭建好了。 更完整的方案，请参考[自动化部署](./automated-deploy.md)
