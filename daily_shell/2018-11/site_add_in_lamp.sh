#!/bin/bash
#本脚本的功能是在LAMP环境中增加站点，包括apache配置、FTP增加用户、MySQL增加库和用户

#网站目录
webdir=/data/wwwroot

#ftp的虚拟用户配置文件目录
ftpudir=/etc/vsftpd/vuuser

#ftp虚拟用户密码文件
ftpuserfile=/root/login

#mysql命令行登录root
mysqlc="/usr/local/mysql/bin/mysql -uroot -pjk1hYUcnt6"

#apache虚拟主机配置文件
httpd_config_f="/usr/local/apache2/conf/extra/httpd-vhosts.conf"

#定义增加MySQL库和用户的函数
add_mysql_user()
{
    #生成随机密码
    mysql_p=`mkpasswd -s 0 -l 12`

    #将密码保存到临时文件里，这里的$pro为用户自定义的项目名字
    echo "$pro $mysql_p" >/tmp/$pro.txt

    #这里使用嵌入文档的形式(需顶格），将创建用户并授权的命令传递给mysql    
$mysqlc <<EOF
create database $pro;
grant all on $pro.* to "$pro"@'127.0.0.1' identified by "$mysql_p";
#下面这个EOF必须要顶格
EOF
}

#定义增加FTP用户的函数
add_ftp_user()
{
    ftp_p=`mkpasswd -s 0 -l 12`
    echo "$pro" >> $ftpuserfile
    echo "$ftp_p" >> $ftpuserfile

    #将用户、密码文件转换为密码db文件
    db_load -T -t hash -f $ftpuserfile  /etc/vsftpd/vsftpd_login.db
    cd $ftpudir

    #这里的aaa是一个文件，是之前的一个项目，可以作为配置模板
    cp aaa $pro 

    #把里面的aaa改为新的项目名字
    sed -i "s/aaa/$pro/" $pro 

    #重启vsftpd服务
    /etc/init.d/vsftpd restart
}

#定义增加apache虚拟主机的函数
config_httpd()
{
    #增加网站根目录，和域名保持一致，这里的$dom为用户自定义的域名
    mkdir $webdir/$dom

    #将网站根目录属主和属组设置为ftp用户
    chown vsftpd:vsftpd $webdir/$dom
    
    #用嵌入文档（需顶格），把虚拟主机配置写入到配置文件里
cat >> $httpd_config_f <<EOF
<VirtualHost *:80>
    DocumentRoot $webdir/$dom
    ServerName $dom
    <Directory $webdir/$dom>
        AllowOverride none
        Require all granted  
    </Directory>
</VirtualHost>
EOF
   
    #重载apache服务
    /usr/local/apache2/bin/apachectl graceful
}

read -p "input the project name: " pro
read -p "input the domain: " dom

add_mysql_user
add_ftp_user
config_httpd
