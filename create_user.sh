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

# 欢迎信息
message_box "终极加密货币服务器安装程序" \
"欢迎使用终极加密货币服务器安装程序！
\n\n安装过程大部分是全自动的。在大多数情况下，所需的用户响应会在安装之前询问。
\n\n注意：您应该只在全新的 Ubuntu 22.04 系统上安装此程序。"

# Root 用户警告信息框
message_box "终极加密货币服务器安装程序" \
"警告！您正在尝试以 root 用户身份安装！
\n\n以 root 用户运行任何应用程序都会带来严重的安全风险。
\n\n因此我们要求您创建一个普通用户账户 :)"

# 询问是否使用 SSH 密钥或密码登录
dialog --title "使用 SSH 密钥创建新用户" \
--yesno "您想要使用 SSH 密钥登录方式创建新用户吗？
选择"否"将创建仅使用密码登录的用户。" 7 60
response=$?
case $response in
   0) UsingSSH=yes;;
   1) UsingSSH=no;;
   255) echo "[ESC] 键被按下.";;
esac

# 如果使用 SSH 密钥登录
if [[ ("$UsingSSH" == "yes") ]]; then
  clear
    if [ -z "${yiimpadmin:-}" ]; then
      DEFAULT_yiimpadmin=yiimpadmin
      input_box "新账户名称" \
      "请输入您想要使用的用户名。
      \n\n用户名:" \
      ${DEFAULT_yiimpadmin} \
      yiimpadmin

      if [ -z "${yiimpadmin}" ]; then
        # 用户按下了 ESC/取消
        exit
      fi
    fi

    if [ -z "${ssh_key:-}" ]; then
      DEFAULT_ssh_key=PublicKey
      input_box "请在本地机器上打开 PuTTY Key Generator 并生成新的公钥。" \
      "要粘贴公钥，请使用 ctrl+shift+右键。
      \n\n公钥:" \
      ${DEFAULT_ssh_key} \
      ssh_key

      if [ -z "${ssh_key}" ]; then
        # 用户按下了 ESC/取消
        exit
      fi
    fi

  # 创建随机用户密码
  RootPassword=$(openssl rand -base64 8 | tr -d "=+/")
  clear

  # 添加用户
  echo -e "正在添加新用户并设置 SSH 密钥...$COL_RESET"
  sudo adduser ${yiimpadmin} --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
  echo -e "${RootPassword}\n${RootPassword}" | passwd ${yiimpadmin}
  sudo usermod -aG sudo ${yiimpadmin}
  
  # 创建 SSH 密钥结构
  mkdir -p /home/${yiimpadmin}/.ssh
  touch /home/${yiimpadmin}/.ssh/authorized_keys
  chown -R ${yiimpadmin}:${yiimpadmin} /home/${yiimpadmin}/.ssh
  chmod 700 /home/${yiimpadmin}/.ssh
  chmod 644 /home/${yiimpadmin}/.ssh/authorized_keys
  authkeys=/home/${yiimpadmin}/.ssh/authorized_keys
  echo "$ssh_key" > "$authkeys"

  # 启用 multipool 命令
  echo '# yiimp
  # 需要无密码 sudo 功能
  '""''"${yiimpadmin}"''""' ALL=(ALL) NOPASSWD:ALL
  ' | sudo -E tee /etc/sudoers.d/${yiimpadmin} >/dev/null 2>&1

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
  PRIVATE_IP='"${PRIVATE_IP}"'' | sudo -E tee /etc/multipool.conf >/dev/null 2>&1

  sudo cp -r ~/multipool /home/${yiimpadmin}/
  cd ~
  sudo setfacl -m u:${yiimpadmin}:rwx /home/${yiimpadmin}/multipool
  sudo rm -r $HOME/multipool
  clear
  echo "新用户已安装，请确保您已保存私钥..."
  echo -e "$RED 请重启系统并以新用户身份登录，然后输入$COL_RESET $GREEN multipool$COL_RESET $RED 继续安装...$COL_RESET"
  exit 0
fi

# 新用户密码登录创建
if [ -z "${yiimpadmin:-}" ]; then
  DEFAULT_yiimpadmin=yiimpadmin
  input_box "新账户名称" \
  "请输入您想要使用的用户名。
  \n\n用户名:" \
  ${DEFAULT_yiimpadmin} \
  yiimpadmin

  if [ -z "${yiimpadmin}" ]; then
    # 用户按下了 ESC/取消
    exit
  fi
fi

if [ -z "${RootPassword:-}" ]; then
  DEFAULT_RootPassword=$(openssl rand -base64 8 | tr -d "=+/")
  input_box "用户密码" \
  "输入您的新用户密码或使用这个系统随机生成的密码。
  \n\n很遗憾 dialog 不允许复制。所以您必须记下来。
  \n\n用户密码:" \
  ${DEFAULT_RootPassword} \
  RootPassword

  if [ -z "${RootPassword}" ]; then
    # 用户按下了 ESC/取消
    exit
  fi
fi

clear

dialog --title "确认您的回答" \
--yesno "请在继续之前确认您的答案：

新用户名：${yiimpadmin}
新用户密码：${RootPassword}" 8 60

# 获取退出状态
# 0 表示用户点击了 [是] 按钮
# 1 表示用户点击了 [否] 按钮
# 255 表示用户按下了 [Esc] 键
response=$?
case $response in

0)
clear
echo -e " 正在添加新用户和密码...$COL_RESET"

sudo adduser ${yiimpadmin} --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
echo -e ""${RootPassword}"\n"${RootPassword}"" | passwd ${yiimpadmin}
sudo usermod -aG sudo ${yiimpadmin}

# 启用 multipool 命令
echo '# yiimp
# 需要无密码 sudo 功能
'""''"${yiimpadmin}"''""' ALL=(ALL) NOPASSWD:ALL
' | sudo -E tee /etc/sudoers.d/${yiimpadmin} >/dev/null 2>&1

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
PRIVATE_IP='"${PRIVATE_IP}"'' | sudo -E tee /etc/multipool.conf >/dev/null 2>&1

sudo cp -r ~/multipool /home/${yiimpadmin}/
cd ~
sudo setfacl -m u:${yiimpadmin}:rwx /home/${yiimpadmin}/multipool
sudo rm -r $HOME/multipool
clear
echo "新用户已安装..."
echo -e "$RED 请重启系统并以新用户身份登录，然后输入$COL_RESET $GREEN multipool$COL_RESET $RED 继续安装...$COL_RESET"
exit 0;;

1)
clear
bash $(basename $0) && exit;;

255)
;;
esac
