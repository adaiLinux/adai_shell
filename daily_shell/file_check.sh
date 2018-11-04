#!/bin/bash
# 对比两台机器上的文件差异

#假设B机器IP为192.168.0.110
B_ip=192.168.0.110
dir=/data/wwwroot/www.abc.com
# 首先检查/tmp/md5.list文件是否存在，存在的话就删除掉，避免影响后续操作
[ -f /tmp/md5.list ] && rm -f /tmp/md5.list

# 把除了uploads以及tmp目录外其他目录下的全部文件列出来
cd $dir
find . \( -path "./uploads*" -o -path "./tmp*" \) -prune -o -type f > /tmp/file.list

# 用while循环，求出所有文件的md5值，并写入一个文件里
cat /tmp/file.list|while read line
do
    md5sum $line 
done  > /tmp/md5.list

# 将md5.list拷贝到B机器
scp /tmp/md5.list $B_ip:/tmp/

# 判断/tmp/check_md5.sh文件是否存在
[ -f /tmp/check_md5.sh ] && rm -f /tmp/check_md5.sh

# 用Here Document编写check_md5.sh脚本内容
cat >/tmp/check_md5.sh << EOF

#!/bin/bash
dir=/data/wwwroot/www.abc.com
##注意，这里涉及到的特殊符号都需要脱义，比如反引号和$
cd \$dir
n=\`wc -l /tmp/md5.list|awk '{print \$1}'\`
for i in \`seq 1 \$n\`
do
    file_name=\`sed -n "\$i"p /tmp/md5.list |awk '{print \$1}'\`
    md5=\`sed -n "\$i"p /tmp/md5.list|awk '{print \$2}'\`
    if [ -f \$file_name ]
    then
        md5_b=\`md5sum \$file_name\`
    if [\$md5_b != \$md5 ]
    then
        echo "\$file_name changed."
    fi
    else
        echo "\$file_name lose."
    fi
done > /data/change.log
EOF
scp /tmp/check_md5.sh $B_ip:/tmp/
ssh $B_ip "/bin/bash /tmp/check_md5.sh"

