### redis 自动化安装脚本

#### 脚本使用安装前配置

> 需要使用root用户执行
> 下载脚本：https://github.com/domdanrtsey/redis_auto_install/tree/master

1. **请注意：**本脚是在Centos7.X上做测试，其他版本的操作系统可能不适合

2. 安装前请将`packages_redis`依赖包、`packages_gcc`依赖包、`redis_install.sh`安装脚本、`redis-5.0.8.tar.gz`软件安装包全数放置在 `/opt` 目录下（可根据情况随意存放）

3. 脚本需要填写所使用的`redis`连接端口，不建议使用6379默认端口，另外建议配置`redis`连接密码同时包含大写字母、小写字母、数字、特殊字符三类以上的组合密码

4. 脚本会判断防火墙，如果不需要开启防火墙，请在以下代码段前添加`#`号注释

   ```shell
   脚本提示reids连接端口如下：
   read -p "Please input the REDISPORT(e.g:6379):" S1
   Please input the REDISPORT(6379)
   
   firewall_status=`systemctl status firewalld | grep Active |awk '{print $3}'`
   if [ ${firewall_status} == "(running)" ];then
     firewall-cmd --permanent --zone=public --add-port=${REDISPORT}/tcp && firewall-cmd --reload
   else
     systemctl start firewalld
     firewall-cmd --permanent --zone=public --add-port=${REDISPORT}/tcp && firewall-cmd --reload
   fi
   
   脚本提示reids连接密码如下：
   read -p "Please input the REDISPWD(e.g:Rdis#2021):" S1
   Please input the REDISPWD(Rdis#2021)
   ```

   

5. 软件运行用户与组是`middle`，如果需要使用其他用户我中，请注意修改

   ```shell
   redis_user=middle
   redis_group=middle
   ```

   

6. 脚本自行判断连接`curl -I -m 10 -o /dev/null -s -w %{http_code}'\n' http://www.baidu.com`是否返回200，返回200表示有网络，将使用`yum`安装相关依赖，否则为无网络情况，使用`rpm`安装所需依赖包（在无网络条件时，请切记上传`packages_redis`、`packages_gcc`，否则脚本将无法自动安装自动安装部署）

7. 脚本提示软件的安装路径是`/usr/local`，请根据实际情况填写，如`/data`、`/app`、`/home/app/`等

   ```shell
   脚本执行提示如下:
   read -p "Please input the REDISPATH(e.g:/usr/local/redis):" S1
   Please input the REDISPATH(/usr/local/redis):
   ```

   

#### 支持系统

- CentOS 7.x 64

> 脚本已经配置`redis`服务自启动，并配置为系统服务，启动与停止时使用`root`用户操作
```shell
停止
# systemctl stop redis
启动
# systemctl start redis
```
> 熟知以上说明之后，开始操作安装部署

```shell
# chmod + redis_install.sh
# sh -x redis_install.sh
```
