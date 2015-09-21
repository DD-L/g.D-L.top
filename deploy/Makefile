CC = gcc
RM = rm -rf
GOOGLE = www.google.com

DEPLOY_LOG = ./deploy.log
UNINSTALL_LOG = ./uninstall.log

all: deploy

deploy:
	bash -x ./deploy.sh > $(DEPLOY_LOG) 2>&1
#	tail -f $(DEPLOY_LOG)


# 像nslookup一样, 在openshift 好像也执行失败了
getgoogleiplist: gethostbyname
	./$< $(GOOGLE) | tee googleips.log

gethostbyname:  gethostbyname.c
	$(CC) $< -o $@ -g

clean:
	$(RM) googleips.log gethostbyname

uninstall_nginx:
	bash -x ./uninstall_nginx.sh >> $(UNINSTALL_LOG) 2>&1

