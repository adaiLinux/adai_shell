#!/bin/bash
#按要求输出XML内容，本脚本定制性较强，不可通用

#假设要处理的XML文档名字为test.xml
#获取<artifactItem>和</artifactItem>所在的行号
grep -n 'artifactItem>' test.xml |awk '{print $1}' |sed 's/://' > /tmp/line_number.txt

#计算<artifactItem>和</artifactItem>的行一共有多少行
n=`wc -l /tmp/line_number.txt|awk '{print $1}'`

#定义获取关键词和其值的函数
get_value(){
    #$1和$2为函数的两个参数，即<artifactItem>下一行和</artifactItem>上一行的行号（这个操作在下面）
    #截取出<artifactItem>和</artifactItem>中间的内容，然后获取关键词（如groupId）和其对应的值，写入/tmp/value.txt
    sed -n "$1,$2"p test.xml|awk -F '<' '{print $2}'|awk -F '>' '{print $1,$2}' > /tmp/value.txt

    #遍历整个/tmp/value.txt文档
    cat /tmp/value.txt|while read line
    do
        #x为关键词，如groupId
        #y为关键词的值
        x=`echo $line|awk '{print $1}'`
        y=`echo $line|awk '{print $2}'`
        echo artifactItem:$x:$y
    done
}

#由于/tmp/line_number.txt是成对出现的，n2为一共多少对
n2=$[$n/2]

#针对每一对，打印关键词和对应的值
for j in `seq 1 $n2`
do
    #每次循环都要处理两行，第一次是1,2，第二次是3,4，依此类推
    m1=$[$j*2-1]
    m2=$[$j*2]

    #每次遍历都要获取<artifactItem>和</artifactItem>的行号
    nu1=`sed -n "$m1"p /tmp/line_number.txt`
    nu2=`sed -n "$m2"p /tmp/line_number.txt`

    #获取<artifactItem>下面一行的行号
    nu3=$[$nu1+1]

     #获取</artifactItem>上面一行的行号
    nu4=$[$nu2-1]

    get_value $nu3 $nu4
done