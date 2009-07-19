#!/usr/bin/env bash

script_dir=`dirname $0`

# nohup ttserver -port 10001 "$script_dir/distdb/shorturl_scrapes-tinyurl.tct#bnum=40000000#opts=l" 2>&1 >> log/ttserver-shorturl_scrapes-tinyurl+`date "+%Y%m%d"`.log &
# nohup ttserver -port 10002 "$script_dir/distdb/shorturl_scrapes-bitly.tct#bnum=20000000#opts=l"   2>&1 >> log/ttserver-shorturl_scrapes-bitly+`date "+%Y%m%d"`.log &
# nohup ttserver -port 10003 "$script_dir/distdb/shorturl_scrapes-other.tct#bnum=20000000#opts=l"   2>&1 >> log/ttserver-shorturl_scrapes-other+`date "+%Y%m%d"`.log &

#
# Start shorturl readthru cache TokyoTyrant servers
#
nohup ttserver -port 10042 "$script_dir/distdb/shorturl_reqs-tinyurl.tch#bnum=40000000#opts=l" 2>&1 >> log/ttserver-shorturl_reqs-tinyurl+`date "+%Y%m%d"`.log &
nohup ttserver -port 10043 "$script_dir/distdb/shorturl_reqs-bitly.tch#bnum=20000000#opts=l"   2>&1 >> log/ttserver-shorturl_reqs-bitly+`date "+%Y%m%d"`.log &
nohup ttserver -port 10044 "$script_dir/distdb/shorturl_reqs-other.tch#bnum=20000000#opts=l"   2>&1 >> log/ttserver-shorturl_reqs-other+`date "+%Y%m%d"`.log &

# nohup ttserver -port 10069 "$script_dir/distdb/shorturl_reqs-foo.tch#bnum=40000000#opts=l" 2>&1 >> log/ttserver-shorturl_reqs-tinyurl+`date "+%Y%m%d"`.log &
