script_dir=`dirname $0`
ttserver -port 10040 $script_dir/work/distdb/shorturl_cache.tct >> $script_dir/work/log/shorturl_cache-`datename`.log 2>&1
