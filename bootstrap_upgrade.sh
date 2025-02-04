#!/usr/bin/env bash


#########################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
# 源自 Mail-in-a-Box 项目，由 cryptopool.builders 更新用于加密货币用途
# 此脚本需要从 multipool 安装程序运行
# 更新支持 Ubuntu 22.04
#########################################################

# 设置默认版本标签
if [ -z "${TAG}" ]; then
	TAG=v1.08
fi

# 如果升级仓库不存在则克隆
if [ ! -d $HOME/multipool/yiimp_upgrade ]; then
	echo "正在下载 MultiPool YiiMP Stratum 升级安装程序 ${TAG}..."
	# 使用 --depth 1 进行浅克隆，只获取最新版本，节省空间和时间
	git clone \
		-b ${TAG} --depth 1 \
		https://github.com/cryptopool-builders/multipool_yiimp_upgrade \
		$HOME/multipool/yiimp_upgrade \
		< /dev/null 2> /dev/null

	echo
fi

# 切换到项目目录
cd $HOME/multipool/yiimp_upgrade

# 更新仓库
# 确保安装目录的 git 权限正确
sudo chown -R $USER $HOME/multipool/install/.git/
if [ "${TAG}" != `git describe --tags` ]; then
	echo "正在更新 MultiPool YiiMP Stratum 升级安装程序到 ${TAG} 版本..."
	# 强制获取指定标签的最新代码
	git fetch --depth 1 --force --prune origin tag ${TAG}
	if ! git checkout -q ${TAG}; then
		echo "更新失败。您是否修改了 `pwd` 中的文件？"
		exit 1
	fi
	echo
fi

# 启动安装脚本
cd $HOME/multipool/yiimp_upgrade || exit
source start.sh
