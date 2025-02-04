#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
# 源自 Mail-in-a-Box 项目，由 cryptopool.builders 更新用于加密货币用途
# 更新支持 Ubuntu 22.04
#####################################################

# 定义终端颜色代码
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
RED=$ESC_SEQ"31;01m"
GREEN=$ESC_SEQ"32;01m"
YELLOW=$ESC_SEQ"33;01m"
BLUE=$ESC_SEQ"34;01m"
MAGENTA=$ESC_SEQ"35;01m"
CYAN=$ESC_SEQ"36;01m"

# 显示加载动画的函数
function spinner {
		local pid=$!
		local delay=0.75
		local spinstr='|/-\'
		while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
				local temp=${spinstr#?}
				printf " [%c]  " "$spinstr"
				local spinstr=$temp${spinstr%"$temp"}
				sleep $delay
				printf "\b\b\b\b\b\b"
		done
		printf "    \b\b\b\b"
}

# 隐藏命令输出的函数，仅在出错时显示
function hide_output {
		# 使用 mktemp 替代 tempfile，因为在新版 Ubuntu 中 tempfile 已弃用
		OUTPUT=$(mktemp)
		$@ &> $OUTPUT & spinner
		E=$?
		if [ $E != 0 ]; then
		echo
		echo "执行失败: $@"
		echo "-----------------------------------------"
		cat $OUTPUT
		echo "-----------------------------------------"
		exit $E
		fi

		rm -f $OUTPUT
}

# 静默执行 apt-get 命令的函数
function apt_get_quiet {
		DEBIAN_FRONTEND=noninteractive hide_output sudo apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" "$@"
}

# 安装软件包的函数
function apt_install {
		PACKAGES=$@
		apt_get_quiet install $PACKAGES
}

# 配置防火墙规则的函数
function ufw_allow {
		if [ -z "$DISABLE_FIREWALL" ]; then
		sudo ufw allow $1 > /dev/null;
		fi
}

# 重启服务的函数
function restart_service {
		# 优先使用 systemctl，如果不可用则回退到 service 命令
		if command -v systemctl >/dev/null 2>&1; then
				hide_output sudo systemctl restart $1
		else
				hide_output sudo service $1 restart
		fi
}

## 对话框函数 ##
# 显示消息框
function message_box {
		dialog --title "$1" --msgbox "$2" 0 0
}

# 显示输入框
function input_box {
		# input_box "标题" "提示" "默认值" 变量名
		# 用户的输入将存储在指定的变量中
		# 对话框的退出代码将存储在 变量名_EXITCODE 中
		declare -n result=$4
		declare -n result_code=$4_EXITCODE
		result=$(dialog --stdout --title "$1" --inputbox "$2" 0 0 "$3")
		result_code=$?
}

# 显示菜单
function input_menu {
		# input_menu "标题" "提示" "标签 项目 标签 项目" 变量名
		# 用户的选择将存储在指定的变量中
		# 对话框的退出代码将存储在 变量名_EXITCODE 中
		declare -n result=$4
		declare -n result_code=$4_EXITCODE
		local IFS=^$'\n'
		result=$(dialog --stdout --title "$1" --menu "$2" 0 0 0 $3)
		result_code=$?
}

# 从网络服务获取公网 IP 地址
function get_publicip_from_web_service {
		# 这是确定机器公网 IP 地址最可靠的方式：
		# 通过查询 web API 来获取。感谢 icanhazip.com 提供服务。
		# 参考：https://major.io/icanhazip-com-faq/
		#
		# 传入 '4' 或 '6' 作为参数来指定获取 IPv4 或 IPv6 地址
		curl -$1 --fail --silent --max-time 15 icanhazip.com 2>/dev/null
}

# 获取默认私有 IP 地址
function get_default_privateip {
		# 返回连接到互联网的网络接口的 IP 地址
		#
		# 传入 '4' 或 '6' 作为参数来指定获取 IPv4 或 IPv6 地址
		#
		# 使用 `ip route get` 让内核根据系统路由选择合适的接口
		# 目标地址使用 8.8.8.8（Google DNS），但不会真正连接
		# 只是用来确定如何路由

		target=8.8.8.8

		# IPv6 路由使用 Google Public DNS 的 IPv6 地址
		if [ "$1" == "6" ]; then target=2001:4860:4860::8888; fi

		# 获取路由信息
		route=$(ip -$1 -o route get $target | grep -v unreachable)

		# 从路由信息中解析出地址
		address=$(echo $route | sed "s/.* src \([^ ]*\).*/\1/")

		# 处理 IPv6 链路本地地址
		if [[ "$1" == "6" && $address == fe80:* ]]; then
		# 对于 IPv6 链路本地地址，从路由信息中解析出接口
		# 并将其附加到地址后面
		interface=$(echo $route | sed "s/.* dev \([^ ]*\).*/\1/")
		address=$address%$interface
		fi

		echo $address
}
