#!bin/bash
#
# init 
instDir=/data/install
[ ! -d $instDir ] && mkdir $instDir

yum -y install lrzsz vim gcc gcc-c++ make wget openssh-clients ntp unzip
if [ $? -ne 0 ];then
   echo "yum install failed 1."
   exit 2   
fi

cd $instDir
# install pcre
wget http://exim.mirror.fr/pcre/pcre-8.38.tar.gz
if [ $? -ne 0 ];then
    echo "安装包pcre-8.38.tar.gz 下载失败." 
    exit 1
else
    tar zxf $instDir/pcre-8.38.tar.gz &> /dev/null ||
    cd pcre-8.38
    ./configure --prefix=/usr/local/pcre &> /dev/null
    make && make install &>/dev/null
    echo "pcre-8.38 安装完成."
fi

# install proxy_cache
cd $instDir
wget http://labs.frickle.com/files/ngx_cache_purge-2.1.tar.gz
if [ -f $instDir/ngx_cache_purge-2.1.tar.gz ];then
  tar zxf ngx_cache_purge-2.1.tar.gz &>/dev/null
  echo "ngx_cache_purge 已解压."
else
  echo "安装包ngx_cache_purge-2.1.tar.gz 下载失败"
  exit 1
fi

# install openssl openssl-devel ,zlib zlib-devel
yum -y install openssl openssl-devel zlib zlib-devel
if [ $? -ne 0 ];then
   echo "yum install failed 2."
   exit 2
fi

# install tengine
cd $instDir
wget http://tengine.taobao.org/download/tengine-2.1.0.tar.gz
if [ $? -eq 0 ];then
    tar -zxvf  tengine-2.1.0.tar.gz   &> /dev/null  
    cd tengine-2.1.0
    ./configure --add-module=$instDir/ngx_cache_purge-2.1 --prefix=/usr/local/nginx --with-http_stub_status_module --with-pcre=$instDir/pcre-8.38 && make -j 8  && make install &>/dev/null
    [ $? -eq 0 ] && echo "tengine-2.1 installed"|| echo "tengine-2.1 安装失败."
else 
    echo "安装包tengine-2.1.0.tar.gz 下载失败." 
    exit 1
fi
