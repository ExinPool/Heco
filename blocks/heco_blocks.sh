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
log_file="$(config_get LOG_FILE)"
webhook_url="$(config_get WEBHOOK_URL)"
access_token="$(config_get ACCESS_TOKEN)"

local_blocks_first_hex=`curl -X POST ${local_host} -H "Content-Type: application/json" --data '{"jsonrpc":"2.0", "method":"eth_blockNumber", "params":[], "id":83}' | jq | grep result | sed "s/\"//g" | awk -F':' '{print $2}' | sed "s/ //g" | sed "s/0x//g"`
local_blocks_first=`echo $((16#${local_blocks_hex}))`
sleep ${sleep_number}
local_blocks_second_hex=`curl -X POST ${local_host} -H "Content-Type: application/json" --data '{"jsonrpc":"2.0", "method":"eth_blockNumber", "params":[], "id":83}' | jq | grep result | sed "s/\"//g" | awk -F':' '{print $2}' | sed "s/ //g" | sed "s/0x//g"`
local_blocks_second=`echo $((16#${local_blocks_hex}))`
log="`date '+%Y-%m-%d %H:%M:%S'` UTC `hostname` `whoami` INFO local_blocks: ${local_blocks}, remote_first_blocks: ${remote_first_blocks}, remote_second_blocks: ${remote_second_blocks}"
echo $log >> $log_file

if [ ${local_blocks_first} -eq ${local_blocks_second} ]
then
    log="时间: `date '+%Y-%m-%d %H:%M:%S'` UTC \n主机名: `hostname` \n节点: ${local_host}, ${local_blocks} \n状态: 同步区块停滞，已重启节点。"
    echo -e $log >> $log_file
    success=`curl ${webhook_url}=${access_token} -XPOST -H 'Content-Type: application/json' -d '{"category":"PLAIN_TEXT","data":"'"$log"'"}' | awk -F',' '{print $1}' | awk -F':' '{print $2}'`
    if [ "$success" = "true" ]
    then
        log="`date '+%Y-%m-%d %H:%M:%S'` UTC `hostname` `whoami` INFO send mixin successfully."
        echo $log >> $log_file
    else
        log="`date '+%Y-%m-%d %H:%M:%S'` UTC `hostname` `whoami` INFO send mixin failed."
        echo $log >> $log_file
    fi
else
    log="`date '+%Y-%m-%d %H:%M:%S'` UTC `hostname` `whoami` INFO ${service} ${local_host} status is normal."
    echo $log >> $log_file
fi