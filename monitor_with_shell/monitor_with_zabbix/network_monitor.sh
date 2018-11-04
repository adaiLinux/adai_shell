#!/bin/bash
#监控网卡流量，当流量为0，重启网卡

#设定语言为英文
LANG=en

#判定系统是否已经安装sysstat包，该包里有sar命令
if ! rpm -q sysstat &>/dev/null
then
    yum install -y sysstat
fi

#将10秒的网卡流量写入到一个临时文件里
sar -n DEV 1 10 |grep 'eth0' > /tmp/eth0_sar.log

#入口网卡流量
net_in=`grep '^Average:' /tmp/eth0_sar.log|awk '{print $5}'`

#出口网卡流量
net_out=`grep '^Average:' /tmp/eth0_sar.log|awk '{print $6}'`

#当入口和出口流量同时为0时，说明网卡异常
if [ $net_in == "0.00" -a $net_out == "0.00" ]
then
    echo "`date` eth0网卡出现异常，重启网卡。">> /tmp/net.log
    ifdown eth0 && ifup eth0
fi
```
#### 扩展参考脚本
```
#!/bin/bash
#监控网卡流量增幅超过一倍告警
#作者：阿铭
#日期：2018-10-07
#版本：v0.1

mail_user=admin@admin.com
dir=/tmp/netlog

[ -d $dir ] || mkdir $dir
s_m=`lsattr -d $dir|awk '{print $1}' |sed 's/[^a]//g'`
if [ $s_m != "a" ]
then
    chattr +a $dir
fi

if ! rpm -q sysstat &>/dev/null
then
    yum install -y sysstat
fi

sar -n DEV 1 10 |grep 'eth0' > /tmp/eth0_sar.log
net_in=`grep '^Average:' /tmp/eth0_sar.log|awk '{print $5}'`
net_out=`grep '^Average:' /tmp/eth0_sar.log|awk '{print $6}'`

if [ ! -f $dir/net.log ]
then
    echo "net_in $net_in" >> $dir/net.log
    echo "net_out $net_out" >> $dir/net.log
    exit 0
fi

net_in_last=`tail -2 $dir/net.log|grep 'net_in'`
net_out_last=`tail -2 $dir/net.log|grep 'net_out'`
net_in_diff=`$[$net_in-$net_in_last]`
net_out_diff=`$[$net_out-$net_out_last]`

if [ $net_in_diff -gt $net_in_last ]
then
    python mail.py $mail_user "网卡入口流量增幅异常" "增幅$net_in_diff"
    #这里的mail.py参考案例二的知识点五
fi

if [ $net_out_diff -gt $net_out_last ]
then
    python mail.py $mail_user "网卡出口流量增幅异常" "增幅$net_out_diff"
fi
    
echo "net_in $net_in" >> $dir/net.log
echo "net_out $net_out" >> $dir/net.log
