#!/usr/bin/python3
#
# 这是一个配置文件编辑辅助工具，用于在安装过程中修改配置文件。
# 该工具通过命令行参数接收新的设置值。它会注释掉配置文件中
# 现有的设置值，并在其原位置后面或文件末尾添加新值。
#
# 配置文件中的设置格式如下：
#
# NAME=VALUE
#
# 如果使用 -s 选项，则使用空格作为分隔符，即：
#
# NAME VALUE
#
# 如果使用 -c 选项，则使用指定的字符作为注释字符
#
# 如果使用 -w 选项，则设置行可以在下一行继续，只要该行以空白字符开始，例如：
#
# NAME VAL
#   UE

import sys, re

# 参数检查
if len(sys.argv) < 3:
	print("用法: python3 editconf.py /etc/file.conf [-s] [-w] [-c <字符>] [-t] NAME=VAL [NAME=VAL ...]")
	sys.exit(1)

# 解析命令行参数
filename = sys.argv[1]
settings = sys.argv[2:]

# 设置默认值
delimiter = "="              # 默认分隔符
delimiter_re = r"\s*=\s*"    # 分隔符的正则表达式
comment_char = "#"           # 默认注释字符
folded_lines = False         # 默认不支持折行
testing = False              # 默认非测试模式

# 处理选项参数
while settings[0][0] == "-" and settings[0] != "--":
	opt = settings.pop(0)
	if opt == "-s":
		# 使用空格作为分隔符
		delimiter = " "
		delimiter_re = r"\s+"
	elif opt == "-w":
		# 此文件中可能存在折行
		folded_lines = True
	elif opt == "-c":
		# 指定不同的注释字符
		comment_char = settings.pop(0)
	elif opt == "-t":
		testing = True
	else:
		print("无效选项。")
		sys.exit(1)

# 检查命令行参数格式
for setting in settings:
	try:
		name, value = setting.split("=", 1)
	except:
		import subprocess
		print("无效的命令行参数: ", subprocess.list2cmdline(sys.argv))

# 在内存中创建新的配置文件

found = set()
buf = ""
input_lines = list(open(filename))

while len(input_lines) > 0:
	line = input_lines.pop(0)

	# 如果配置文件使用折行，将所有折行
	# 添加到输入缓冲区
	if folded_lines and line[0] not in (comment_char, " ", ""):
		while len(input_lines) > 0 and input_lines[0][0] in " \t":
			line += input_lines.pop(0)

	# 检查这行是否匹配命令行参数中的任何设置
	for i in range(len(settings)):
		# 检查这行是否包含来自命令行参数的设置
		name, val = settings[i].split("=", 1)
		m = re.match(
			   "(\s*)"                           # 开头空白
			 + "(" + re.escape(comment_char) + "\s*)?"  # 可选的注释字符
			 + re.escape(name) + delimiter_re + "(.*?)\s*$",  # 名称和值
			 line, re.S)
		if not m: continue
		indent, is_comment, existing_val = m.groups()

		# 如果这已经是设置值，不做任何事
		if is_comment is None and existing_val == val:
			# 可能我们已经在文件上方插入了这个设置
			# 所以先检查那种情况
			if i in found: break
			buf += line
			found.add(i)
			break

		# 注释掉现有行（同时注释任何折行）
		if is_comment is None:
			buf += comment_char + line.rstrip().replace("\n", "\n" + comment_char) + "\n"
		else:
			# 该行已经被注释，直接传递
			buf += line

		# 如果这个选项奇怪地出现多次，不要再次添加设置
		if i in found:
			break

		# 添加新设置
		buf += indent + name + delimiter + val + "\n"

		# 注意我们已经应用了这个选项
		found.add(i)

		break
	else:
		# 如果没有匹配任何设置名称，保持原样
		buf += line

# 将任何没有看到的设置添加到文件末尾
for i in range(len(settings)):
	if i not in found:
		name, val = settings[i].split("=", 1)
		buf += name + delimiter + val + "\n"

if not testing:
	# 写出新文件
	with open(filename, "w") as f:
		f.write(buf)
else:
	# 仅打印到标准输出
	print(buf)
