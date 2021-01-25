#!/bin/bash
# script_name: redis_install.sh
# Author: Danrtsey.Shun
# Email:mydefiniteaim@126.com
# auto_install_redis version=5.0.8
#################### Upload redis software ####################
#|     version: redis-5.0.8.tar.gz   |#
#|     packages: packages_gcc        |#
#|     packages: packages_redis      |#
#|     script: redis_install.sh      |#
#
#################### Install redis software ####################
# attentions:
# 1.上传软件包/依赖包/redis_install.sh至服务器任意路径下，如 /opt
#
# 2.执行
# chmod + redis_install.sh
# sh -x redis_install.sh


export PATH=$PATH
#Source function library.
. /etc/init.d/functions

#Require root to run this script.
uid=`id | cut -d\( -f1 | cut -d= -f2`
if [ $uid -ne 0 ];then
  action "Please run this script as root." /bin/false
  exit 1
fi

###set firewalld & optimize the os system & set selinux
echo "################# Optimize system parameters  ##########################"
count=0
while [ $count -lt 3 ]
do
        read -p "Please input the REDISPORT(e.g:6379):" S1
        read -p "Please input the REDISPORT again(6379):" S2
        if [ "${S1}" == "${S2}" ];then
                export REDISPORT=${S1}
                break
        else    
                echo "You input REDISPORT not same."
                count=$[${count}+1]
        fi 
done

firewall_status=`systemctl status firewalld | grep Active |awk '{print $3}'`
if [ ${firewall_status} == "(running)" ];then
  firewall-cmd --permanent --zone=public --add-port=${REDISPORT}/tcp && firewall-cmd --reload
else
  systemctl start firewalld
  firewall-cmd --permanent --zone=public --add-port=${REDISPORT}/tcp && firewall-cmd --reload
fi

# 特定IP192.168.142.166可访问本机7369端口
# count=0
# while [ $count -lt 3 ]
# do
#         read -p "Please input the IPADDR(e.g:192.168.142.166):" S1
#         read -p "Please input the IPADDR again(192.168.142.166):" S2
#         if [ "${S1}" == "${S2}" ];then
#                 export IPADDR=${S1}
#                 break
#         else    
#                 echo "You input IPADDR not same."
#                 count=$[${count}+1]
#         fi 
# done
# firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="${IPADDR}" port protocol="tcp" port="${REDISPORT}" accept"
# firewall-cmd --reload
# 特定IP段192.168.142.0/24可访问本机7369端口
# count=0
# while [ $count -lt 3 ]
# do
#         read -p "Please input the IP_ADDR(e.g:192.168.142.0):" S1
#         read -p "Please input the IP_ADDR again(192.168.142.0):" S2
#         if [ "${S1}" == "${S2}" ];then
#                 export IP_ADDR=${S1}
#                 break
#         else    
#                 echo "You input IP_ADDR not same."
#                 count=$[${count}+1]
#         fi 
# done
# firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="${IP_ADDR}/24" port protocol="tcp" port="${REDISPORT}" accept"
# firewall-cmd --reload


SELINUX=`cat /etc/selinux/config |grep ^SELINUX=|awk -F '=' '{print $2}'`
if [ ${SELINUX} == "enforcing" ];then
  sed -i "s@SELINUX=enforcing@SELINUX=disabled@g" /etc/selinux/config
else
  if [ ${SELINUX} == "permissive" ];then
    sed -i "s@SELINUX=permissive@SELINUX=disabled@g" /etc/selinux/config
  fi
fi
setenforce 0

###set the ip in hosts
echo "############################   Ip&Hosts Configuration  #######################################"
hostname=`hostname`
HostIP=`ip a|grep 'inet '|grep -v '127.0.0.1'|awk '{print $2}'|awk -F '/' '{print $1}'`
for i in ${HostIP}
do
    A=`grep "${i}" /etc/hosts`
    if [ ! -n "${A}" ];then
        echo "${i} ${hostname}" >> /etc/hosts 
    else
        break
    fi
done

###set the sysctl,limits and profile
echo "############################   Configure environment variables #######################################"
D=`grep 'ip_local_port_range' /etc/sysctl.conf`
if [ ! -n "${D}" ];then
cat << EOF >> /etc/sysctl.conf
fs.file-max = 6815744
vm.overcommit_memory = 1
net.core.somaxconn=1024
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 10240 87380 12582912
net.ipv4.tcp_wmem = 10240 87380 12582912
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 40960
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 30
net.ipv4.ip_local_port_range = 1024 65000
EOF
/sbin/sysctl -p
fi
E=`grep '65535' /etc/security/limits.conf`
if [ ! -n "${E}" ];then
cat << EOF >> /etc/security/limits.conf
* soft nproc 16384
* hard nproc 16384
* soft nofile 65535
* hard nofile 65535
EOF
fi

echo never > /sys/kernel/mm/transparent_hugepage/enabled
cat >>/etc/rc.local<<EOF
echo never > /sys/kernel/mm/transparent_hugepage/enable
EOF

echo "############################   Create Group&User  #######################################"
redis_user=middle
redis_group=middle
groupadd -r ${redis_group} && useradd -s /sbin/nologin -r -g ${redis_group} ${redis_user}


count=0
while [ $count -lt 3 ]
do
        read -p "Please input the REDISPWD(e.g:Rdis#2021):" S1
        read -p "Please input the REDISPWD again(Rdis#2021):" S2
        if [ "${S1}" == "${S2}" ];then
                export REDISPWD=${S1}
                break
        else    
                echo "You input REDISPWD not same."
                count=$[${count}+1]
        fi 
done

count=0
while [ $count -lt 3 ]
do
        read -p "Please input the REDISPATH(e.g:/usr/local/redis):" S1
        read -p "Please input the REDISPATH again(/usr/local/redis):" S2
        if [ "${S1}" == "${S2}" ];then
                export REDISPATH=${S1}
                break
        else    
                echo "You input REDISPATH not same."
                count=$[${count}+1]
        fi 
done
if [ ! -d ${REDISPATH} ];then
    mkdir -pv ${REDISPATH}/{log,data,etc,run}
fi
chown -R ${redis_user}:${redis_group} ${REDISPATH}

#------------------------------------------------OFF--VERSION------------------------------------------------------#
redis_version=`basename redis-*.tar.gz .tar.gz | awk -F '-' '{print$2}'`
#------------------------------------------------ON---VERSION------------------------------------------------------#
redisv="5.0.8"
#------------------------------------------------SOFTWARE_PATH--------------------------------------------------------#
softwarepath=$(cd `dirname $0`; pwd)
gccoffpath=${softwarepath}/packages_gcc
redisoffpath=${softwarepath}/packages_redis

 #------------------------------------------------------GCCSTRAT----------------------------------------------------#
function environment(){
    echo "|------------------------ CHECK GCC--------------------------|"
    GCCBIN=`which gcc`
    GCCV=$(echo $GCCBIN | grep "gcc")
    if [[ "$GCCV" != "" ]]
    then
        echo "gcc was installed "
    else
        echo "install gcc starting"
        httpcode=`curl -I -m 10 -o /dev/null -s -w %{http_code}'\n' http://www.baidu.com`
        net1=$(echo $httpcode | grep "200")
        if [[ "$net1" != "" ]];then
          echo "|-----------------------[    成功    ]-----------------------|"
          echo "|-----------------------[准备联网安装]-----------------------|"
          /usr/bin/sleep 2
          yum install gcc gcc-c++ -y >/dev/null 2>&1
          gcc -v >/dev/null 2>&1
          if [[ $? -eq 0 ]]; then
            echo "gcc was on_installed successed"
          else
            echo "gcc was on_installed failed"
          exit 2
          fi
        else
          echo "|-----------------------[    失败    ]-----------------------|"
          echo "|-----------------------[检测不到网络]-----------------------|"
          echo "|-----------------------[准备离线安装]-----------------------|"
          /usr/bin/sleep 2
          gccinstall_off
        fi
    fi
}

function gccinstall_off(){
    echo "|---------------------[正在安装离线包]----------------------|"
    cd ${gccoffpath}
    rpm -ivh *.rpm --nodeps --force
    gcc -v
    if [[ $? -eq 0 ]]; then
        echo "gcc was off_installed successed"
    else
        echo "gcc was off_installed failed"
		exit 3
    fi
}
 #------------------------------------------------------GCCEND----------------------------------------------------#
 #------------------------------------------------------REDISSTRAT----------------------------------------------------#
function redis(){
    echo "install redis starting"
    httpcode=`curl -I -m 10 -o /dev/null -s -w %{http_code}'\n' http://www.baidu.com`
    net1=$(echo $httpcode | grep "200")
    if [[ "$net1" != "" ]]
      then
      echo "|-----------------------[    成功    ]-----------------------|"
      echo "|-----------------------[准备联网安装]-----------------------|"
      /usr/bin/sleep 2
      yum install automake autoconf libtool make wget net-tools vim -y >/dev/null 2>&1
	  redis_on
    else
      echo "|-----------------------[    失败    ]-----------------------|"
      echo "|-----------------------[检测不到网络]-----------------------|"
      echo "|-----------------------[准备离线安装]-----------------------|"
      /usr/bin/sleep 2
      redisinstall_off
    fi
}

function redis_on(){
    echo "|---------------------[正在源码安装]----------------------|"
    cd ${softwarepath}
    redis=`ls | grep redis-*.tar.gz`
    if [[ "$redis" != "" ]];then
      tar -zxvf redis-${redis_version}.tar.gz >/dev/null 2>&1
	  cd redis-${redis_version}/src
      make all && make install PREFIX=${REDISPATH}
      if [[ $? -ne 0 ]]; then
        echo "redis was off_make_installed failed"
        exit 4
      else
        echo "redis off_make_installed successed"
        touch ${REDISPATH}/log/redis.log
        cp ${softwarepath}/redis-${redis_version}/redis.conf ${REDISPATH}/etc
        cp ${softwarepath}/redis-${redis_version}/src/mkreleasehdr.sh ${REDISPATH}/bin/
        chown -R ${redis_user}:${redis_group} ${REDISPATH}
        cd ${REDISPATH}/etc/
        sed -i "s/daemonize no/daemonize yes/g" redis.conf
        sed -i "s/^bind 127.0.0.1/bind 0.0.0.0/g" redis.conf
        sed -i "s/^port 6379/port ${REDISPORT}/g" redis.conf
        sed -i "s@pidfile /var/run/redis_6379.pid@pidfile ${REDISPATH}/run/redis_${REDISPORT}.pid@g" redis.conf
        sed -i "s@logfile ""@logfile "${REDISPATH}/log/redis.log"@g" redis.conf
        sed -i "s@^dir ./@dir ${REDISPATH}/data@g" redis.conf
        sed -i "s@^# requirepass foobared@requirepass '${REDISPWD}'@g" redis.conf
        sed -i '523irename-command CONFIG ""' redis.conf
        sed -i '524irename-command FLUSHALL ""' redis.conf
        sed -i '525irename-command FLUSHDB ""' redis.conf
      fi
    else
      echo "please upload the redis-*.tar.gz"
      exit 5
    fi
}

function redisinstall_off(){
    echo "|---------------------[正在安装离线包]----------------------|"
    cd ${redisoffpath}
	rpm -ivh *.rpm --nodeps --force
    echo "|---------------------[正在源码安装]----------------------|"
    cd ${softwarepath}
    redis=`ls | grep redis-*.tar.gz`
    if [[ "$redis" != "" ]];then
      tar -zxvf redis-${redis_version}.tar.gz >/dev/null 2>&1
	  cd redis-${redis_version}/src
      make all && make install PREFIX=${REDISPATH}
      if [[ $? -ne 0 ]]; then
        echo "redis was off_make_installed failed"
        exit 6
      else
        echo "redis off_make_installed successed"
        touch ${REDISPATH}/log/redis.log
        cp ${softwarepath}/redis-${redis_version}/redis.conf ${REDISPATH}/etc
        cp ${softwarepath}/redis-${redis_version}/src/mkreleasehdr.sh ${REDISPATH}/bin/
        chown -R ${redis_user}:${redis_group} ${REDISPATH}
        cd ${REDISPATH}/etc/
        sed -i "s/daemonize no/daemonize yes/g" redis.conf
        sed -i "s/^bind 127.0.0.1/bind 0.0.0.0/g" redis.conf
        sed -i "s/^port 6379/port ${REDISPORT}/g" redis.conf
        sed -i "s@pidfile /var/run/redis_6379.pid@pidfile ${REDISPATH}/run/redis_${REDISPORT}.pid@g" redis.conf
        sed -i "s@logfile ""@logfile "${REDISPATH}/log/redis.log"@g" redis.conf
        sed -i "s@^dir ./@dir ${REDISPATH}/data@g" redis.conf
        sed -i "s@^# requirepass foobared@requirepass '${REDISPWD}'@g" redis.conf
        sed -i '523irename-command CONFIG ""' redis.conf
        sed -i '524irename-command FLUSHALL ""' redis.conf
        sed -i '525irename-command FLUSHDB ""' redis.conf
      fi
    else
      echo "please upload the redis-*.tar.gz"
      exit 7
    fi
}

function redis_service(){
echo "############################   redis sys_service  #######################################"
cat >/etc/systemd/system/redis.service <<EOF
[Unit]
Description=redis-server
Requires=network-online.target
After=network.target

[Service]
Type=simple
ExecStart=${REDISPATH}/bin/redis-server ${REDISPATH}/etc/redis.conf --daemonize no
Restart=always
RestartSec=5
User=${redis_user}
Group=${redis_group}
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable redis
systemctl start redis
if [ $? -ne 0 ];then
  action "redis service start failed." /bin/false
  exit 8
fi

systemctl stop redis
if [ $? -ne 0 ];then
  action "redis service stop failed." /bin/false
  exit 9
fi

systemctl restart redis
if [ $? -ne 0 ];then
  action "redis service restart failed." /bin/false
  exit 10
fi
ps -ef|grep redis
}

#----------------------------------------------------REDISEND-------------------------------------------------------#

function main(){
environment
redis
redis_service
}
main