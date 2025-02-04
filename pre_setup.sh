#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
# 源自 Mail-in-a-Box 项目，由 cryptopool.builders 更新用于加密货币用途
# 更新支持 Ubuntu 22.04
#####################################################

source /etc/functions.sh
clear
echo -e " 正在设置全局变量..."

# 如果机器在 NAT 后面、在虚拟机内等，它可能不知道自己在公共网络/互联网上的 IP 地址
# 询问互联网并可能与用户确认
if [ -z "${PUBLIC_IP:-}" ]; then
# 询问互联网
GUESSED_IP=$(get_publicip_from_web_service 4)

# 在第一次运行时，如果我们从互联网得到答案，就不要询问用户
if [[ -z "${DEFAULT_PUBLIC_IP:-}" && ! -z "$GUESSED_IP" ]]; then
PUBLIC_IP=$GUESSED_IP

# 在后续运行中，如果之前的值与猜测值匹配，也不要询问用户
elif [ "${DEFAULT_PUBLIC_IP:-}" == "$GUESSED_IP" ]; then
PUBLIC_IP=$GUESSED_IP
fi

if [ -z "${PUBLIC_IP:-}" ]; then
input_box "公网 IP 地址" \
"请输入此机器的公网 IP 地址（由您的 ISP 提供）。
\n\n公网 IP 地址:" \
"$DEFAULT_PUBLIC_IP" \
PUBLIC_IP

if [ -z "$PUBLIC_IP" ]; then
# 用户按下了 ESC/取消
exit
fi
fi
fi

# IPv6 的处理方式相同，但它是可选的
# 如果系统看起来没有 IPv6，就不要询问
if [ -z "${PUBLIC_IPV6:-}" ]; then
	# 询问互联网
	GUESSED_IP=$(get_publicip_from_web_service 6)
	MATCHED=0
	if [[ -z "${DEFAULT_PUBLIC_IPV6:-}" && ! -z "$GUESSED_IP" ]]; then
		PUBLIC_IPV6=$GUESSED_IP
	elif [[ "${DEFAULT_PUBLIC_IPV6:-}" == "$GUESSED_IP" ]]; then
		# 没有输入 IPv6 且机器似乎没有，或者用户输入的内容与互联网告诉我们的匹配
		PUBLIC_IPV6=$GUESSED_IP
		MATCHED=1
	elif [[ -z "${DEFAULT_PUBLIC_IPV6:-}" ]]; then
		DEFAULT_PUBLIC_IP=$(get_default_privateip 6)
	fi

	if [[ -z "${PUBLIC_IPV6:-}" && $MATCHED == 0 ]]; then
		input_box "IPv6 地址（可选）" \
			"请输入此机器的公网 IPv6 地址（由您的 ISP 提供）。
			\n\n如果机器没有 IPv6 地址，请留空。
			\n\n公网 IPv6 地址:" \
			${DEFAULT_PUBLIC_IPV6:-} \
			PUBLIC_IPV6

		if [ ! $PUBLIC_IPV6_EXITCODE ]; then
			# 用户按下了 ESC/取消
			exit
		fi
	fi
fi

# 自动配置，例如在我们的 Vagrant 配置中使用
if [ "$PUBLIC_IP" = "auto" ]; then
# 使用公共 API 获取我们的公网 IP 地址，或回退到本地网络配置
PUBLIC_IP=$(get_publicip_from_web_service 4 || get_default_privateip 4)
fi
if [ "$PUBLIC_IPV6" = "auto" ]; then
# 使用公共 API 获取我们的公网 IPv6 地址，或回退到本地网络配置
PUBLIC_IPV6=$(get_publicip_from_web_service 6 || get_default_privateip 6)
fi
