#!/bin/bash
USER=$1
PASSWORD=$2
OTP=$3
ZIP_FILE_NAME=$4
CODE_NAME=$5

NOT_DEPLOYED_HOST=()
NOT_INSTALLED_HOST=()
for HOST in `cat bin/deploy/.tailscale-ip`
do
	echo "hostname: $HOST"

	# 1. deploy - scp로 zip 패키지 전송
	bin/deploy/deploy.exp $USER $HOST $PASSWORD $OTP $ZIP_FILE_NAME > /dev/null
	sleep 10
	# 1-1. deploy check
	bin/deploy/deploy-check.exp $USER $HOST $PASSWORD $OTP $ZIP_FILE_NAME > deploy_check_$HOST.txt
	sleep 10
	bin/deploy/deploy-check.sh $HOST $ZIP_FILE_NAME
	result=$?

	if [[ $result -eq 1 ]]
	then
		NOT_DEPLOYED_HOST+=( $HOST )
		NOT_INSTALLED_HOST+=( $HOST )
	else
		# 2. install - edge서버에서 해당 모듈을 사용할 수 있도록 압축 해제 & 패키지 설치
		bin/deploy/install.exp $USER $HOST $PASSWORD $OTP $ZIP_FILE_NAME $CODE_NAME > install_check_$HOST.txt
		sleep 10
		# 2-2. install check 
		bin/deploy/install-check.exp $USER $HOST $PASSWORD $OTP $CODE_NAME > version_check_$HOST.txt
		sleep 10
		bin/deploy/install-check.sh $HOST
		result=$?

		if [[ $result -eq 1 ]]
		then
			NOT_INSTALLED_HOST+=( $HOST )
		fi
	fi
	echo -e "\n"
done

if [[ -z ${NOT_DEPLOYED_HOST} && -z ${NOT_INSTALLED_HOST} ]]
then
	echo "Deploy와 Install에 모두 성공하였습니다"
else
	echo "Deploy와 Install에 실패한 기기들의 hostname은 다음과 같습니다"
	echo "Deploy: ${NOT_DEPLOYED_HOST[@]}"
	echo "Install: ${NOT_INSTALLED_HOST[@]}"
	exit 1
fi