#!/usr/bin/env bash

#####################################################
# This is the entry point for configuring the system.
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
# 这是系统配置的入口点
# 源自 Mail-in-a-Box 项目,由 cryptopool.builders 更新用于加密货币用途
# 更新支持 Ubuntu 22.04
#####################################################

# 如果存在配置文件,则加载之前的设置
if [ -f /etc/multipool.conf ]; then
# Load the old .conf file to get existing configuration options loaded
# into variables with a DEFAULT_ prefix.
# 加载旧的配置文件,将现有配置选项加载到带有 DEFAULT_ 前缀的变量中
cat /etc/multipool.conf | sed s/^/DEFAULT_/ > /tmp/multipool.prev.conf
source /tmp/multipool.prev.conf
rm -f /tmp/multipool.prev.conf
else
FIRST_TIME_SETUP=1
fi

# 首次安装时的设置
if [[ ("$FIRST_TIME_SETUP" == "1") ]]; then
  clear
  cd $HOME/multipool/install

  source functions.sh
  # 将函数文件复制到 /etc 目录
  sudo cp -r functions.sh /etc/
  sudo cp -r editconf.py /usr/bin
  sudo chmod +x /usr/bin/editconf.py

  # 检查系统设置:是否以 root 身份在 Ubuntu 22.04 上运行,且内存足够
  source preflight.sh

  # 确保 Python 以 UTF-8 编码读写文件
  # 如果系统触发其他区域设置(如 ASCII),Python 可能无法正确读写文件
  if ! locale -a | grep en_US.utf8 > /dev/null; then
  # 如果不存在则生成 locale
  hide_output locale-gen en_US.UTF-8
  fi

  # 设置语言环境变量
  export LANGUAGE=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
  export LANG=en_US.UTF-8
  export LC_TYPE=en_US.UTF-8

  # 修复在 Windows 的 Putty 中显示线条字符的问题
  export NCURSES_NO_UTF8_ACS=1

  # 安装必要的软件包
  echo -e " 正在安装所需的软件包...$COL_RESET"
  sudo apt-get -q -q update
  # 更新为 Ubuntu 22.04 兼容的软件包安装命令
  DEBIAN_FRONTEND=noninteractive apt_get_quiet install \
    dialog \
    python3 \
    python3-pip \
    acl \
    nano \
    git \
    apt-transport-https \
    software-properties-common \
    curl \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    || exit 1

  # 安装 Python 依赖
  python3 -m pip install --upgrade pip
  python3 -m pip install setuptools wheel

  # 检查是否以 root 身份运行
  if [[ $EUID -ne 0 ]]; then
    # 欢迎信息
    message_box "终极加密货币服务器安装程序" \
    "欢迎使用终极加密货币服务器安装程序！
    \n\n安装过程大部分是全自动的。在大多数情况下，所需的用户响应会在安装之前询问。
    \n\n注意：您应该只在全新的 Ubuntu 22.04 系统上安装此程序。"
    source existing_user.sh
    exit
    else
    source create_user.sh
    exit
  fi
	cd ~

else
# 非首次安装的处理流程
clear

# 设置 UTF-8 编码环境
	if ! locale -a | grep en_US.utf8 > /dev/null; then
	   # 如果不存在则生成 locale
	    hide_output locale-gen en_US.UTF-8
	fi
	export LANGUAGE=en_US.UTF-8
	export LC_ALL=en_US.UTF-8
	export LANG=en_US.UTF-8
	export LC_TYPE=en_US.UTF-8
	# 修复在 Windows 的 Putty 中显示线条字符的问题
	export NCURSES_NO_UTF8_ACS=1

  # 加载函数和变量
	source /etc/functions.sh
	source /etc/multipool.conf
  # 启动多池安装程序
	cd $HOME/multipool/install
	source menu.sh
	echo
	echo "-----------------------------------------------"
	echo
	echo "感谢使用终极加密货币服务器安装程序！"
	echo
	echo "要随时运行此安装程序，只需输入：multipool"
	echo "如果您觉得这个脚本对您有帮助，欢迎通过以下地址捐赠支持："
	echo
	# 接受以下加密货币的捐赠
	echo "比特币(BTC): 3DvcaPT3Kio8Hgyw4ZA9y1feNnKZjH7Y21"
	echo "比特币现金(BCH): qrf2fhk2pfka5k649826z4683tuqehaq2sc65nfz3e"
	echo "以太坊(ETH): 0x6A047e5410f433FDBF32D7fb118B6246E3b7C136"
	echo "莱特币(LTC): MLS5pfgb7QMqBm3pmBvuJ7eRCRgwLV25Nz"
	cd ~
fi
