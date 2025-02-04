#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
# 源自 Mail-in-a-Box 项目，由 cryptopool.builders 更新用于加密货币用途
#####################################################

# 检查 Ubuntu 版本
# 更新支持 Ubuntu 22.04
if [ "`lsb_release -d | sed 's/.*:\s*//' | sed 's/22\.04\.[0-9]/22.04/' `" == "Ubuntu 22.04 LTS" ]; then
  DISTRO=22
  sudo chmod g-w /etc /etc/default /usr
elif [ "`lsb_release -d | sed 's/.*:\s*//' | sed 's/18\.04\.[0-9]/18.04/' `" == "Ubuntu 18.04 LTS" ]; then
  DISTRO=18
  sudo chmod g-w /etc /etc/default /usr
else
  echo "错误：本安装程序仅支持 Ubuntu 22.04 LTS"
  echo "当前系统版本: $(lsb_release -d | sed 's/.*:\s*//')"
  exit
fi

# 检查系统内存
TOTAL_PHYSICAL_MEM=$(head -n 1 /proc/meminfo | awk '{print $2}')
if [ $TOTAL_PHYSICAL_MEM -lt 1436000 ]; then
  if [ ! -d /vagrant ]; then
    TOTAL_PHYSICAL_MEM=$(expr \( \( $TOTAL_PHYSICAL_MEM \* 1024 \) / 1000 \) / 1000)
    echo "您的加密货币矿池服务器需要更多内存(RAM)才能正常运行。"
    echo "请配置至少 1536 MB 内存，建议 6 GB。"
    echo "当前机器内存: $TOTAL_PHYSICAL_MEM MB"
    exit
  fi
fi

# 内存不足警告
if [ $TOTAL_PHYSICAL_MEM -lt 1436000 ]; then
  echo "警告：您的加密货币矿池服务器内存少于 1.5 GB。"
  echo "在高负载时可能会运行不稳定。"
fi

# 检查并配置交换空间
echo "正在检查是否需要创建交换空间..."

# 获取系统当前状态
SWAP_MOUNTED=$(cat /proc/swaps | tail -n+2)
SWAP_IN_FSTAB=$(grep "swap" /etc/fstab)
ROOT_IS_BTRFS=$(grep "\/ .*btrfs" /proc/mounts)
TOTAL_PHYSICAL_MEM=$(head -n 1 /proc/meminfo | awk '{print $2}')
AVAILABLE_DISK_SPACE=$(df / --output=avail | tail -n 1)

# 检查是否需要创建交换文件
if
  [ -z "$SWAP_MOUNTED" ] &&        # 没有已挂载的交换空间
  [ -z "$SWAP_IN_FSTAB" ] &&      # fstab 中没有配置交换空间
  [ ! -e /swapfile ] &&           # 不存在交换文件
  [ -z "$ROOT_IS_BTRFS" ] &&      # 根文件系统不是 BTRFS
  [ $TOTAL_PHYSICAL_MEM -lt 1536000 ] &&  # 物理内存小于 1.5GB
  [ $AVAILABLE_DISK_SPACE -gt 5242880 ]   # 有足够的磁盘空间(>5GB)
then
  echo "正在添加交换文件到系统..."

  # 分配并激活交换文件，以 1KB 为单位分配
  # 一次性分配可能在低内存系统上失败
  sudo fallocate -l 3G /swapfile
    if [ -e /swapfile ]; then
      sudo chmod 600 /swapfile
      hide_output sudo mkswap /swapfile
      sudo swapon /swapfile
      echo "vm.swappiness=10" >> sudo /etc/sysctl.conf
    fi

  # 检查交换空间是否已挂载，然后设置开机自动启用
  if swapon -s | grep -q "\/swapfile"; then
    echo "/swapfile  none swap sw 0  0" >> sudo /etc/fstab
  else
    echo "错误：交换空间分配失败"
  fi
fi

# 检查系统架构
ARCHITECTURE=$(uname -m)
if [ "$ARCHITECTURE" != "x86_64" ]; then
  if [ -z "$ARM" ]; then
    echo "终极加密货币服务器安装程序仅支持 x86_64 架构，不支持其他架构（如 ARM 或 32 位操作系统）。"
    echo "当前系统架构: $ARCHITECTURE"
    exit
  fi
fi

# 设置存储用户和根目录
# 如果没有从之前的运行中获取值，则设置默认值
# (crypto-data 和 /home/crypto-data)
if [ -z "$STORAGE_USER" ]; then
  STORAGE_USER=$([[ -z "$DEFAULT_STORAGE_USER" ]] && echo "crypto-data" || echo "$DEFAULT_STORAGE_USER")
fi
if [ -z "$STORAGE_ROOT" ]; then
  STORAGE_ROOT=$([[ -z "$DEFAULT_STORAGE_ROOT" ]] && echo "/home/$STORAGE_USER" || echo "$DEFAULT_STORAGE_ROOT")
fi
