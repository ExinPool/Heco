#!/bin/bash
#
# Copyright © 2019 ExinPool <robin@exin.one>
#
# Distributed under terms of the MIT license.
#
# Desc: Heco blocks monitor.
# User: Robin@ExinPool
# Date: 2021-09-25
# Time: 09:02:38

# load the config library functions
source config.shlib

# load configuration
service="$(config_get SERVICE)"
local_host="$(config_get LOCAL_HOST)"
sleep_number="$(config_get SLEEP_NUMBER)"
process="$(config_get PROCESS)"
process_num="$(config_get PROCESS_NUM)"
process_num_var=`sudo netstat -langput | grep LISTEN | grep $process | wc -l`
log_file="$(config_get LOG_FILE)"
lark_webhook_url="$(config_get LARK_WEBHOOK_URL)"

local_blocks_first_hex=`curl -X POST ${local_host} -H "Content-Type: application/json" --data '{"jsonrpc":"2.0", "method":"eth_blockNumber", "params":[], "id":83}' | jq | grep result | sed "s/\"//g" | awk -F':' '{print $2}' | sed "s/ //g" | sed "s/0x//g"`
local_blocks_first=`echo $((16#${local_blocks_first_hex}))`
sleep ${sleep_number}
local_blocks_second_hex=`curl -X POST ${local_host} -H "Content-Type: application/json" --data '{"jsonrpc":"2.0", "method":"eth_blockNumber", "params":[], "id":83}' | jq | grep result | sed "s/\"//g" | awk -F':' '{print $2}' | sed "s/ //g" | sed "s/0x//g"`
local_blocks_second=`echo $((16#${local_blocks_second_hex}))`
log="`date '+%Y-%m-%d %H:%M:%S'` UTC `hostname` `whoami` INFO local_blocks: ${local_blocks}, remote_first_blocks: ${remote_first_blocks}, remote_second_blocks: ${remote_second_blocks}"
echo $log >> $log_file

if [ ${process_num} -eq ${process_num_var} ] && [ ${local_blocks_first} -eq ${local_blocks_second} ]
then
    log="时间: `date '+%Y-%m-%d %H:%M:%S'` UTC \n主机名: `hostname` \n节点: ${local_host}, ${local_blocks} \n状态: 同步区块停滞，已重启节点。"
    echo -e $log >> $log_file
    curl -X POST -H "Content-Type: application/json" -d '{"msg_type":"text","content":{"text":"'"$log"'"}}' ${lark_webhook_url}
    cd /data/heco && bash stop.sh
    sleep 5
    cd /data/heco && bash start.sh
else
    log="`date '+%Y-%m-%d %H:%M:%S'` UTC `hostname` `whoami` INFO ${service} ${local_host} blocks status is normal."
    echo $log >> $log_file
fi