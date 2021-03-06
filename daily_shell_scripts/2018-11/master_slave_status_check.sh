#!/bin/bash
#检测MySQL主从是否同步

#把脚本名字存入变量s_name
s_name=`echo $0|awk -F '/' '{print $NF}'`
Mysql_c="mysql -uroot -ptpH40Kznv"

#该函数实现邮件告警收敛，在案例五种出现过，通用
m_mail() {
    log=$1
    t_s=`date +%s`
    t_s2=`date -d "1 hours ago" +%s`
    if [ ! -f /tmp/$log ]
    then
        #创建$log文件
        touch /tmp/$log 
        #增加a权限，只允许追加内容，不允许更改或删除
        chattr +a /tmp/$log
        #第一次告警，可以直接写入1小时以前的时间戳
        echo $t_s2 >> /tmp/$log
    fi
    #无论$log文件是否是刚刚创建，都需要查看最后一行的时间戳
    t_s2=`tail -1 /tmp/$log|awk '{print $1}'`
    #取出最后一行即上次告警的时间戳后，立即写入当前的时间戳
    echo $t_s>>/tmp/$log
    #取两次时间戳差值
    v=$[$t_s-$t_s2]
    #如果差值超过1800，立即发邮件
    if [ $v -gt 1800 ]
    then
        #发邮件，其中$2为mail函数的第二个参数，这里为一个文件
        python mail.py $mail_user $1 "`cat $2`"  2>/dev/null   
        #定义计数器临时文件，并写入0         
        echo "0" > /tmp/$log.count
    else
        #如果计数器临时文件不存在，需要创建并写入0
        if [ ! -f /tmp/$log.count ]
        then
            echo "0" > /tmp/$log.count
        fi
        nu=`cat /tmp/$log.count`
        #30分钟内每发生1次告警，计数器加1
        nu2=$[$nu+1]
        echo $nu2>/tmp/$log.count
        #当告警次数超过30次，需要再次发邮件
        if [ $nu2 -gt 30 ]
        then
             python mail.py $mail_user "$1 30 min" "`cat $2`" 2>/dev/null  
             #第二次告警后，将计数器再次从0开始          
             echo "0" > /tmp/$log.count
        fi
    fi
}

#把进程情况存入临时文件，如果加管道求行数会有问题
ps aux |grep "$s_name" |grep -vE "$$|grep">/tmp/ps.tmp
p_n=`wc -l /tmp/ps.tmp|awk '{print $1}'`

#当进程数大于0，则说明上次的脚本还未执行完
if [ $p_n -gt 0 ]
then
    exit
fi

#先执行一条执行show processlist，看是否执行成功
$Mysql_c -e "show processlist" >/tmp/mysql_pro.log 2>/tmp/mysql_log.err

#如果上一条命令执行不成功，说明这个MySQL服务出现了问题
if [ $? -gt 0 ]
then
    m_mail mysql_service_error /tmp/mysql_log.err
    exit
else
    $Mysql_c -e "show slave status\G" >/tmp/mysql_s.log
    n1=`wc -l /tmp/mysql_s.log|awk '{print $1}'`

    if [ $n1 -gt 0 ]
    then
        y1=`grep 'Slave_IO_Running:' /tmp/mysql_s.log|awk -F : '{print $2}'|sed 's/ //g'`
        y2=`grep 'Slave_SQL_Running:' /tmp/mysql_s.log|awk -F : '{print $2}'|sed 's/ //g'`

        if [ $y1 == "No" ] || [ $y2 == "No" ]
        then
            m_mail mysql_slavestatus_error /tmp/mysql_s.log  
        fi
    fi
fi
