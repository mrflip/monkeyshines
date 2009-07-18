#!/usr/bin/env bash

script_dir=`dirname $0`

#
# Start shorturl readthru cache TokyoTyrant servers
#
nohup ttserver -port 10001 $script_dir/distdb/shorturl_scrapes-tinyurl.tct 2>&1 >> log/ttserver-shorturl_scrapes-tinyurl+`date "+%Y%m%d"`.log &
nohup ttserver -port 10002 $script_dir/distdb/shorturl_scrapes-bitly.tct   2>&1 >> log/ttserver-shorturl_scrapes-bitly+`date "+%Y%m%d"`.log &
nohup ttserver -port 10003 $script_dir/distdb/shorturl_scrapes-other.tct   2>&1 >> log/ttserver-shorturl_scrapes-other+`date "+%Y%m%d"`.log &
