#!/bin/bash

LONG=host:,user:,password:,otp:,process-name:,slack-channel:
OPTS=$(getopt -o '' -a --longoptions $LONG  -- "$@")
[ $? -eq 0 ] || {
    echo "인자전달이 잘못되었습니다."
    exit 1
}
eval set -- "$OPTS"

while [[ $# -gt 0 ]]
do
	case "$1" in
	--host)
	  HOST=$2
	  shift 2
	  ;;
	--user)
		USER=$2
		shift 2
		;;
	--password)
		PASSWORD=$2
		shift 2
		;;
	--otp)
		OTP=$2
		shift 2
		;;
	--process-name)
		PROCESS_NAME=$2
		shift 2
		;;
	--slack-channel)
		SLACK_CHANNEL=$2
		shift 2
		;;
	--)
		shift
		break
		;;
	esac
done

vpn_ip_to_device_id() {
	TARGET_HOSTS_VPN_IP=$1
  DEVICE_ID=$(edge-info-search --query vpn_ip=="$TARGET_HOSTS_VPN_IP" -c device_id)
	echo "${TARGET_DEVICES_ID[@]}"
}

# 프로세스 켜기
action/start-process.exp "$USER" "$HOST" "$PASSWORD" "$OTP" "$PROCESS_NAME"
start_result=$?
echo -e "\n"

# 결과 메세지 처리
DEVICE_ID=$(vpn_ip_to_device_id "${HOST}")
if [[ $start_result == 0 ]]
then
  deploy_result_message="DEVICE $DEVICE_ID 의 $PROCESS_NAME 시작에 성공했습니다"
  exitcode=0
else
  deploy_result_message="DEVICE $DEVICE_ID 의 $PROCESS_NAME 시작에 실패했습니다"
  exitcode=1
fi
echo "$deploy_result_message"

if [[ -n $SLACK_CHANNEL ]]
then
  source /etc/profile
  slackboy send --message "${deploy_result_message}" --channel "${SLACK_CHANNEL}" --prefix cd-start-process
fi
exit $exitcode