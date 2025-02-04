#####################################################
# Source code https://github.com/end222/pacmenu
# Updated by cryptopool.builders for crypto use...
# 源自 pacmenu 项目，由 cryptopool.builders 更新用于加密货币用途
# 更新支持 Ubuntu 22.04
#####################################################

# 加载函数库
source /etc/functions.sh

# 显示主菜单并获取用户选择
RESULT=$(dialog --stdout --nocancel --default-item 1 \
    --title "终极加密货币服务器安装程序 v2.55" \
    --menu "请选择要安装的服务" -1 60 16 \
    ' ' "- YiiMP 服务器安装 -" \
    1 "YiiMP 单服务器" \
    2 "YiiMP 多服务器集群" \
    ' ' "- YiiMP 升级 -" \
    3 "YiiMP Stratum 升级" \
    ' ' "- NOMP 服务器安装 -" \
    4 "NOMP 服务器" \
    ' ' "- MPOS 服务器安装 -" \
    5 "MPOS 服务器 - 即将推出" \
    ' ' "- CryptoNote 服务器安装 -" \
    6 "CryptoNote-Nodejs 服务器 - 即将推出" \
    ' ' "- 水龙头服务器安装 -" \
    7 "水龙头脚本 - 即将推出" \
    ' ' "- 守护钱包构建器 -" \
    8 "守护进程构建器" \
    9 "退出")

# 如果用户没有选择，重新显示菜单
if [ $RESULT = ]
then
    bash $(basename $0) && exit;
fi

# 处理用户选择
case $RESULT in
    1)  # YiiMP 单服务器安装
        clear
        cd $HOME/multipool/install
        source bootstrap_single.sh
        ;;
    
    2)  # YiiMP 多服务器安装
        clear
        cd $HOME/multipool/install
        source bootstrap_multi.sh
        ;;
    
    3)  # YiiMP Stratum 升级
        clear
        cd $HOME/multipool/install
        source bootstrap_upgrade.sh
        ;;
    
    4)  # NOMP 服务器安装
        clear
        cd $HOME/multipool/install
        source bootstrap_nomp.sh
        ;;
    
    5|6|7)  # 未实现的功能
        clear
        cd $HOME/multipool/install
        echo "此功能尚未实现，敬请期待！"
        sleep 3
        bash $(basename $0)
        ;;
    
    8)  # 守护进程构建器
        clear
        cd $HOME/multipool/install
        source bootstrap_coin.sh
        ;;
    
    9)  # 退出程序
        clear
        exit
        ;;
esac
