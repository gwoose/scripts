#!/bin/bash
#
#Filename:      mysql_install.sh
#Revision:      1.0
#Date:          /09/22/2016
#Author:        guowang
#Email:         guowang@vjidian.com
#Function:      编译安装mysql 5.6
#Changelog:     由原来的干净环境一次运行，
# 				  1.添加对二次运行的支持：包括已存在的用户、安装包、解压安装包的目录（此前做保留，此后做删除重建）、数据目录、安装目录、数据库配置文件、服务配置文件；
#				  2.添加版本选择，目前支持：mysql-5.6.31、mysql-5.6.33、mysql-5.6.13，应该是5.6都支持的。

# 安装路径
instDir=/opt
# 数据路径
datadir=/data/mysqldb
# mysql安装路径
basedir=/usr/local/mysql
# 提前安装的软件列表
pkgs="lrzsz vim gcc gcc-c++ make wget openssh-clients ntp unzip ncurses-devel perl cmake"
# mysql 包版本全称，目前可以是 mysql-5.6.31  |  mysql-5.6.33  |  mysql-5.6.13
mysql="mysql-5.6.31"   

# 安装的需要的软件
yum -y install $pkgs
if [ $? -ne 0 ];then
   echo "yum install failed."
   exit 2
fi

# 检测用户mysql是否存在
id mysql 
[ $? -eq 0  ] || useradd -s /sbin/nologin mysql

# 检测安装路径，数据路径是否存在，存在则删除
[ -d $datadir ] && rm -fr $datadir
mkdir $datadir
[ -d $basedir ] && rm -fr $basedir
mkdir -pv $basedir

# 更改安装路径，数据路径权限
chown -R mysql:mysql  $basedir
chown -R mysql:mysql  $datadir

# 进行源码编译安装
cd $instDir
## 检测是否存在下载好的包，否则下载
[ -s $instDir/$mysql.tar.gz  ] || wget http://dev.mysql.com/get/Downloads/MySQL-5.6/$mysql.tar.gz
if [ $? -ne 0 ];then
   echo "安装包$mysql.tar.gz 下载失败."
   exit 1 
fi

## 检测是否已经解压，否则解压
[ -s $instDir/$mysql ] || tar xf $mysql.tar.gz
cd $mysql

## 编译安装
cmake -DCMAKE_INSTALL_PREFIX=$basedir -DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EXTRA_CHARSETS=all -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_MEMORY_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1 -DMYSQL_DATADIR=$datadir -DMYSQL_USER=mysql && make -j8 && make install
if [ $? -ne 0 ];then
   echo "安装$mysql失败."
   exit 3
fi

# 简单修改数据库配置文件
rm -f /etc/my.cnf 
cp -f support-files/my-default.cnf /etc/my.cnf
sed -i "/\[mysqld\]/a \log-bin=mysql-bin"        	 /etc/my.cnf
sed -i "/\[mysqld\]/a \innodb-file-per-table=ON" 	 /etc/my.cnf
sed -i "s@# basedir = .*@basedir=$basedir@g"    	 /etc/my.cnf
sed -i "s@# datadir = .*@datadir=$datadir@g"      	 /etc/my.cnf
sed -i "/\[mysqld\]/a \lower_case_table_names=1"  	 /etc/my.cnf
sed -i "s@# socket = .*@socket =/tmp/mysql.sock@g"   /etc/my.cnf

# 简单修改启动脚本
rm -f /etc/init.d/mysqld
cp support-files/mysql.server /etc/init.d/mysqld
chmod +x /etc/init.d/mysqld  									# 给脚本添加执行权限
#sed -i "s@basedir=@basedir=$basedir@" /etc/init.d/mysqld		# MySQL安装目录
#sed -i "s@datadir=@datadir=$datadir@" /etc/init.d/mysqld       # 数据存放目录

# 添加开机启动
chkconfig mysqld on
sed -i '/export PATH=$basedir\/bin:$PATH/d' /etc/profile
echo "export PATH=$basedir/bin:$PATH" >>/etc/profile
source /etc/profile

# 安装一个依赖关系
yum -y install 'perl(Data::Dumper)'
if [ $? -ne 0 ];then
   echo "yum install perl(Data::Dumper) failed."
   exit 2
fi

# 初始化数据库
chmod +x scripts/mysql_install_db
scripts/mysql_install_db --datadir=$datadir --basedir=$basedir

# 更改文件权限
chown -R mysql.mysql $datadir 
chown -R mysql.mysql $basedir

# 启动程序和 mysql环境安全初始化
service mysqld start && exec mysql_secure_installation 
