#!/bin/bash
WORK_DIR="$( cd "$( dirname "$0"  )" && pwd  )"
action=$@
if [ "$1" == "potatso" ]; then
	FLAG=potatso
	FILENAME="Potatso.conf"
elif [ "$1" == "postern" ]; then
	FLAG=postern
	FILENAME="Postern.conf"
elif [ "$1" == "shadowrocket" ]; then
	FLAG=shadowrocket
	FILENAME="Shadowrocket.conf"
else
	echo "Parameter Error [$action]"
	exit
fi
dList=$(ls direct*.txt)
rList=$(ls reject*.txt)
cd "$WORK_DIR"
echo "# by benzBrake http://doufu.ru" > ${FILENAME}
echo "# Update" >> ${FILENAME}
if [ "$FLAG" == "potatso" ]; then
	SUFFIX="  - DOMAIN-SUFFIX"
	MATCH="  - DOMAIN-MATCH"
	CIDR="  - IP-CIDR"
	echo "ruleSets:" >> ${FILENAME}
	echo "- name: JooJump" >> ${FILENAME}
	echo "  rules: " >> ${FILENAME}
elif [ "$FLAG" == "postern" ]; then
	SUFFIX="DOMAIN-SUFFIX"
	MATCH="DOMAIN-KEYWORD"
	CIDR="IP-CIDR"
	echo "[General]" >> ${FILENAME}
	echo " " >> ${FILENAME}
	echo "[Rule]" >> ${FILENAME}
elif [ "$FLAG" == "shadowrocket" ]; then
	SUFFIX="DOMAIN-SUFFIX"
	MATCH="DOMAIN-KEYWORD"
	CIDR="IP-CIDR"
	echo "[General]" >> ${FILENAME}
	echo "bypass-system = true" >> ${FILENAME}
	echo "skip-proxy = 192.168.0.0/24,10.0.0.0/8,172.16.0.0/12,localhost,*.local,e.crashlynatics.com,12306.cn" >> ${FILENAME}
	echo "bypass-tun = 10.0.0.0/8,100.64.0.0/10,127.0.0.0/8,169.254.0.0/16,172.16.0.0/12,192.0.0.0/24,192.0.2.0/24,192.88.99.0/24,192.168.0.0/24,198.18.0.0/15,198.51.100.0/24,203.0.113.0/24,224.0.0.0/4,255.255.255.255/32" >> ${FILENAME}
	echo "dns-server = 8.8.8.8,8.8.4.4" >>${FILENAME}
	echo " " >> ${FILENAME}
	echo "[Rule]" >> ${FILENAME}
fi
echo "# REJECT" >> ${FILENAME}
for item in ${rList}
do
	result=$(echo $item | grep "_cn.txt")
	if [[ "$result" == "" ]]; then
		result=$(echo $item | grep "domain_match")
		if [[ "$result" != "" ]]; then
			cat "$item" | while read line
			do
				echo "${MATCH},${line},REJECT" >> ${FILENAME}
			done
		else
			cat "$item" | while read line
			do
				echo ${line} | egrep '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' >/dev/null
				if [ $? -ne 0 ];then
					echo "${SUFFIX},${line},REJECT" >> ${FILENAME}
				else
					echo "${CIDR},${line},REJECT" >> ${FILENAME}
				fi
			done
		fi
	fi
done
echo "# DIRECT" >> ${FILENAME}
for item in ${dList}
do
	result=$(echo $item | grep "domain_match")
	if [[ "$result" != "" ]]; then
		cat "$item" | while read line
		do
			echo "${MATCH},${line},Direct" >> ${FILENAME}
		done
	else
		cat "$item" | while read line
		do
			echo ${line} | egrep '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' >/dev/null
			if [ $? -ne 0 ];then
				echo "${SUFFIX},${line},Direct" >> ${FILENAME}
			else
				echo "${CIDR},${line},Direct" >> ${FILENAME}
			fi
		done
	fi

done
if [ "$FLAG" == "potatso" ]; then
	echo "" >/dev/null
elif [ "$FLAG" == "postern" ]; then
	echo "FINAL,DIRECT" >> ${FILENAME}
elif [ "$FLAG" == "shadowrocket" ]; then
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