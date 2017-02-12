#!/bin/bash
WORK_DIR="$( cd "$( dirname "$0"  )" && pwd  )"
action=$@
if [ "$1" == "potatso" ]; then
	FLAG=potatso
	FILENAME="Potatso_CN.conf"
elif [ "$1" == "postern" ]; then
	FLAG=postern
	FILENAME="Postern_CN.conf"
elif [ "$1" == "shadowrocket" ]; then
	FLAG=shadowrocket
	FILENAME="Shadowrocket_CN.conf"
else
	echo "Parameter Error [$action]"
	exit
fi
echo "# by benzBrake http://doufu.ru" > ${FILENAME}
echo "# Update" >> ${FILENAME}
if [ "$FLAG" == "potatso" ]; then
	SUFFIX="  - DOMAIN-SUFFIX"
	MATCH="  - DOMAIN-MATCH"
	CIDR="  - IP-CIDR"
	echo "ruleSets:" >> ${FILENAME}
	echo "- name: JooJump - CN" >> ${FILENAME}
	echo "  rules: " >> ${FILENAME}
elif [ "$FLAG" == "postern" ]; then
	SUFFIX="DOMAIN-SUFFIX"
	MATCH="DOMAIN-KEYWORD"
	CIDR="IP-CIDR"
	echo "[General]" >> ${FILENAME}
	echo " " >> ${FILENAME}
	echo "[Proxy]" >> ${FILENAME}
	echo "Proxy = shadowsocks,8.8.8.8,1080,aes-256-cfb,password" >> ${FILENAME}
	echo "[Rule]" >> ${FILENAME}
elif [ "$FLAG" == "shadowrocket" ]; then
	SUFFIX="DOMAIN-SUFFIX"
	MATCH="DOMAIN-KEYWORD"
	CIDR="IP-CIDR"
	echo "[General]" >> ${FILENAME}
	echo "bypass-system = true" >> ${FILENAME}
	echo "skip-proxy = 192.168.0.0/24,10.0.0.0/8,172.16.0.0/12,localhost,*.local,e.crashlynatics.com,12306.cn" >> ${FILENAME}
	echo "bypass-tun = 10.0.0.0/8,100.64.0.0/10,127.0.0.0/8,169.254.0.0/16,172.16.0.0/12,192.0.0.0/24,192.0.2.0/24,192.88.99.0/24,192.168.0.0/24,198.18.0.0/15,198.51.100.0/24,203.0.113.0/24,224.0.0.0/4,255.255.255.255/32" >> ${FILENAME}
	echo " " >> ${FILENAME}
	echo "[Rule]" >> ${FILENAME}
fi
if [ -f proxy.txt ]; then
	echo "# Proxy" >> ${FILENAME}
	cat proxy.txt | while read line
	do
		echo ${line} | egrep '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' >/dev/null
		if [ $? -ne 0 ];then
			echo "${SUFFIX},${line},Proxy" >> ${FILENAME}
		else
			echo "${CIDR},${line},Proxy" >> ${FILENAME}
		fi
	done
fi
if [ -f proxy_domain_match.txt ]; then
	cat proxy_domain_match.txt | while read line
	do
		echo ${line} | egrep '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' >/dev/null
		if [ $? -ne 0 ];then
			echo "${MATCH},${line},Proxy" >> ${FILENAME}
		else
			echo "${CIDR},${line},Proxy" >> ${FILENAME}
		fi
	done
fi
if [ -f reject.txt ]; then
	echo "# REJECT" >> ${FILENAME}
	cat reject.txt | while read line
	do
		echo ${line} | egrep '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' >/dev/null
		if [ $? -ne 0 ];then
			echo "${SUFFIX},${line},REJECT" >> ${FILENAME}
		else
			echo "${CIDR},${line},REJECT" >> ${FILENAME}
		fi
	done
fi
if [ -f reject_domain_match.txt ]; then
	cat reject_domain_match.txt | while read line
	do
		echo ${line} | egrep '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' >/dev/null
		if [ $? -ne 0 ];then
			echo "${MATCH},${line},REJECT" >> ${FILENAME}
		else
			echo "${CIDR},${line},REJECT" >> ${FILENAME}
		fi
	done
fi
if [ -f reject_video_ads_cn.txt ]; then
	cat reject_video_ads_cn.txt | while read line
	do
		echo ${line} | egrep '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' >/dev/null
		if [ $? -ne 0 ];then
			echo "${SUFFIX},${line},REJECT" >> ${FILENAME}
		else
			echo "${CIDR},${line},REJECT" >> ${FILENAME}
		fi
	done
fi
if [ -f direct.txt ]; then
	echo "# DIRECT" >> ${FILENAME}
	cat direct.txt | while read line
	do
		echo ${line} | egrep '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' >/dev/null
		if [ $? -ne 0 ];then
			echo "${SUFFIX},${line},Direct" >> ${FILENAME}
		else
			echo "${CIDR},${line},Direct" >> ${FILENAME}
		fi
	done
fi
if [ "$FLAG" == "potatso" ]; then
	echo "  - GEOIP,CN,DIRECT" >> ${FILENAME}
elif [ "$FLAG" == "postern" ]; then
	echo "GEOIP,CN,DIRECT" >> ${FILENAME}
	echo "FINAL,DIRECT" >> ${FILENAME}
elif [ "$FLAG" == "shadowrocket" ]; then
	echo "GEOIP,CN,DIRECT" >> ${FILENAME}
	echo "FINAL,DIRECT" >> ${FILENAME}
fi
cd "$WORK_DIR"
if [ -f ../${FILENAME} ];then
	if [ -f PRE_${FILENAME} ]; then
		rm -f PRE_${FILENAME}
	fi
	cp ../${FILENAME} ./PRE_${FILENAME}
	sed -i "s@# Update.*@# Update@" PRE_${FILENAME}
	diff ${FILENAME} PRE_${FILENAME} >/dev/null
	if [ $? -ne 0 ]; then
		rm -f ../${FILENAME}
		cp ${FILENAME} ../${FILENAME}
		echo "Update ${FLAG} Successful"
		sed -i "s@# Update.*@# Update: $(date '+%Y%m%d %T')@" ../${FILENAME}
	else
		echo "Do Nothing"
	fi
else
	echo "Update ${FLAG} Successful"
	cp ${FILENAME} ../
	sed -i "s@# Update.*@# Update: $(date '+%Y%m%d %T')@" ../${FILENAME}
fi
rm -f PRE_${FILENAME} ${FILENAME}