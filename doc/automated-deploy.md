# 自动化部署

采用自动化部署方案可以配置一个完整的服务器。

-------------------

#####在部署前，请确保你已经完成了 [准备工作](./pre-works.md)

1. 无特别说明，手动部署文档仍然以我的配置为例：

	1. app域名: http://nginx-deel.rhcloud.com/
	2. 二级openshift域名: deel
	3. app名： nginx
	3. 本地仓库文件夹： openshift_nginx

2. 一些可能有帮助的 [openshift 环境变量](https://developers.openshift.com/en/managing-environment-variables.html).

-----------------------

####操作步骤

步骤虽然是很多，但每一个步骤都及其简单。

1. git clone
	
	<pre>
	$ git clone https://github.com/DD-L/g.D-L.top
	</pre>

	在自己的PC上clone我的仓库代码。这里你要关注3个目录：
	
	1. ./g.D-L.top/.openshift/
	2. ./g.D-L.top/deploy/
	3. ./g.D-L.top/www/
	
2. 修改 ./g.D-L.top/deploy/nginx.conf.template

	将文件中出现 'g.d-l.top' 的，都修改为你自己的域名，只需要一行命令。

	全部要修改，这里以linux下为例，假定你的域名是 nginx-mydomain.rhcloud.com：
	
	<pre>
	$ cd g.D-L.top
	$ sed -i "s/g.[dD]-[lL].top/nginx-mydomain.rhcloud.com/g" ./deploy/nginx.conf.template
	</pre>
	
	windows 有更好的可视化字符串替换工具，这里不再过多的介绍。

3. 修改 ./g.D-L.top/www/deelroot/index.html
	<pre>
	< title > Welcome to g.D-L.top < /title >
	< a href="http://g.D-L.top/webhp?hl=zh-CN" >
	</pre>
	两处 出现 'g.D-L.top' 的地方, 修改为你自己的域名。

4. copy 相关目录，到你openshift的本地仓库目录openshift_nginx下
	
	<pre>
	比如
	$ cp -a ./g.D-L.top/.openshift/ ./openshift_nginx/
	$ cp -a ./g.D-L.top/deploy/ ./openshift_nginx/
	$ cp -a ./g.D-L.top/www/ ./openshift_nginx/
	</pre>

5. 提交代码

	请确保在 `git push` 之前, 关停正在运行的ruby server, 这个操作是在 [准备工作](./pre-works.md) 中完成的。

	<pre>
	$ cd ./openshift_nginx/
	$ git status
	$ # 将出现改动或新增的文件，全部添加到仓库中去
	$ git add .openshift/action_hooks/ .openshift/cron/* deploy/ www/
	$ # 查看是否还有漏余
	$ git status
	$ # 检查没有遗漏后，提交到仓库中去
	$ git commit -m "start nginx"
	$ # 最后 push 到远程仓库
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

6. 在线自动化部署
	
	ssh 到你的远程主机，执行以下命令：
	<pre>
	$ cd $OPENSHIFT_REPO_DIR/deploy/
	$ make deploy # 或直接执行 make
	</pre>
	
	deploy 的日志在 $OPENSHIFT_REPO_DIR/deploy/deploy.log 中
	
	如果你想查看deploy的进度，可再开一个ssh终端，执行
	<pre>
	$ tail -f $OPENSHIFT_REPO_DIR/deploy/deploy.log
	</pre>

	当终端出现 "Deployment has been completed..." 字样时，说明deploy已经完成。

	如果是其它情况，请参考日志 $OPENSHIFT_REPO_DIR/deploy/deploy.log, 并把相关问题及时反馈给我。

7. 重启nginx

	这里要用 openshift 上的工具重启你的网站
	
	在远程主机上执行：
	
	<pre>
	$ /usr/bin/gear stop
	$ /usr/bin/gear start
	</pre>
	
	浏览器访问你的网站，以验证服务器是否正常工作。

8. 卸载刚刚部署的服务器
	
	如果你反悔了，想卸载刚刚部署的服务器。可以执行自动化卸载工具
	
	在远程主机上执行:
	<pre>
	$ cd $OPENSHIFT_REPO_DIR/deploy/
	$ make uninstall_nginx 
	</pre>
	卸载产生的日志文件在 $OPENSHIFT_REPO_DIR/deploy//uninstall.log 中.
	