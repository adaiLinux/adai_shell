#!/bin/bash
##批量添加100个用户，user01-user100

#检查是否有mkpasswd命令
#如果没有该命令，需要安装expect包
if ! which mkpasswd &>/dev/null 
then
    echo "没有mkpasswd命令，安装该命令："
    yum install -y expect
fi

#判断/data/user_passwd文件是否已经存在
#若存在，应该先删除掉
[ -f /data/user_passwd ] && rm -f /data/user_passwd

#因为100为三位数，所以只能遍历到99
for n in `seq  -w 1 99`
do
    pass=`mkpasswd -l 12 -s 0`
    echo "添加用户user_$n"
    useradd -g users user_$n
    echo "给用户user_$n设定密码"
    echo $pass |passwd --stdin user_$n
    echo "user_$n $pass" >>/data/user_passwd
done

pass=`mkpasswd -l 12 -s 0`
echo "添加用户user_100"
useradd -g users user_100
echo "给用户user100设定密码"
echo $pass|passwd --stdin user_100
echo "user_100 $pass" >>/data/user_passwd
