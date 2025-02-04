#!/usr/bin/env bash
#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
# 源自 Mail-in-a-Box 项目，由 cryptopool.builders 更新用于加密货币用途
# 更新支持 Ubuntu 22.04
#####################################################

source /etc/functions.sh
cd ~/multipool/install
clear

# 获取当前登录用户名
whoami=`whoami`
echo -e " 正在为 multipool 支持修改现有用户 $whoami。"
sudo usermod -aG sudo ${whoami}

# 配置 sudo 权限
echo '# yiimp
# 需要无密码 sudo 功能
'""''"${whoami}"''""' ALL=(ALL) NOPASSWD:ALL
' | sudo -E tee /etc/sudoers.d/${whoami} >/dev/null 2>&1

# 创建 multipool 命令
echo '
cd ~/multipool/install
bash start.sh
' | sudo -E tee /usr/bin/multipool >/dev/null 2>&1
sudo chmod +x /usr/bin/multipool

# 检查必需文件并设置全局变量
cd $HOME/multipool/install
source pre_setup.sh

# 如果 STORAGE_USER 和 STORAGE_ROOT 目录不存在则创建
if ! id -u $STORAGE_USER >/dev/null 2>&1; then
sudo useradd -m $STORAGE_USER
fi
if [ ! -d $STORAGE_ROOT ]; then
sudo mkdir -p $STORAGE_ROOT
fi

# 将全局选项保存到 /etc/multipool.conf
echo 'STORAGE_USER='"${STORAGE_USER}"'
STORAGE_ROOT='"${STORAGE_ROOT}"'
PUBLIC_IP='"${PUBLIC_IP}"'
PUBLIC_IPV6='"${PUBLIC_IPV6}"'
DISTRO='"${DISTRO}"'
FIRST_TIME_SETUP='"${FIRST_TIME_SETUP}"'
PRIVATE_IP='"${PRIVATE_IP}"'' | sudo -E tee /etc/multipool.conf >/dev/null 2>&1

cd ~
sudo setfacl -m u:${whoami}:rwx /home/${whoami}/multipool
clear
echo -e " 您的用户已经被修改以支持 multipool..."
echo -e "$RED 您必须重启系统以更新新权限，然后输入$COL_RESET $GREEN multipool$COL_RESET $RED 继续安装...$COL_RESET"
exit 0
