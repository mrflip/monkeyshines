#!/usr/bin/env ruby
$: << '/home/flip/ics/wukong/lib' # 'ENV['WUKONG_DIR'] if ENV['WUKONG_DIR']
require 'wukong'

SHORTURL_RE = %r{^http://(?:1link.in|4url.cc|6url.com|adjix.com|ad.vu|bellypath.com|bit.ly|bkite.com|budurl.com|canurl.com|chod.sk|cli.gs|decenturl.com|dn.vc|doiop.com|dwarfurl.com|easyuri.com|easyurl.net|ff.im|go2cut.com|gonext.org|hulu.com|hypem.com|ifood.tv|ilix.in|is.gd|ix.it|jdem.cz|jijr.com|kissa.be|kurl.us|litturl.com|lnkurl.com|memurl.com|metamark.net|miklos.dk|minilien.com|minurl.org|muhlink.com|myurl.in|myurl.us|notlong.com|ow.ly|plexp.com|poprl.com|qurlyq.com|redirx.com|s3nt.com|shorterlink.com|shortlinks.co.uk|short.to|shorturl.com|shrinklink.co.uk|shrinkurl.us|shrt.st|shurl.net|simurl.com|shorl.com|smarturl.eu|snipr.com|snipurl.com|snurl.com|sn.vc|starturl.com|surl.co.uk|tighturl.com|timesurl.at|tiny123.com|tiny.cc|tinylink.com|tinyurl.com|tobtr.com|traceurl.com|tr.im|tweetburner.com|twitpwr.com|twitthis.com|twurl.nl|u.mavrev.com|ur1.ca|url9.com|urlborg.com|urlbrief.com|urlcover.com|urlcut.com|urlhawk.com|url-press.com|urlsmash.com|urltea.com|urlvi.be|vimeo.com|wlink.us|xaddr.com|xil.in|xrl.us|x.se|xs.md|yatuc.com|yep.it|yweb.com|zi.ma|w3t.org)/}
class Mapper < Wukong::Streamer::Base

  def process rsrc, url, tweet_id, user_id
    yield url if url =~ SHORTURL_RE
  end
end

Wukong::Script.new(Mapper, nil).run
