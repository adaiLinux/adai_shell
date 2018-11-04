#/bin/bash
#监控指定页面是否是非200状态码

url="http://www.test.com/test.html"
mail_user=admin@admin.com

#检查是否有curl命令
if ! which curl &>/dev/null
then
    yum install -y curl
fi

#定义告警函数（这里的mail.py是案例二中那个脚本）
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
        python mail.py $mail_user "$url访问异常" "`cat $2`"  2>/dev/null
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
             python mail.py $mail_user "$url访问异常持续30分钟了" "`cat $2`" 2>/dev/null
             #第二次告警后，将计数器再次从0开始
             echo "0" > /tmp/$log.count
        fi
    fi
}

curl -I $url &>/tmp/curl.txt
code=`grep '^HTTP/1.1' /tmp/curl.txt|awk '{print $2}'`
if [ -z "$code" ] || [ $code -ne 200 ]
then
    m_mail webcode /tmp/curl.txt
fi
