class ShorturlRequest < Struct.new(
    :url,
    :scraped_at,
    :response_code, :response_message,
    :contents
    )
  alias_method :short_url=, :url=
  alias_method :expanded_url,  :contents
  alias_method :expanded_url=, :contents=
  #
  # All we care about is the redirect destination.
  #
  def response= response
    self.expanded_url = response["location"]
  end

  #
  # The major shortening services
  #
  # Do any of the mainstream shorteners use in-band characters besides \w
  # alphanum and - dash?  (idek.net uses a ~ and pastoid.com a + but they
  # are not popular enough to justify the annoyance of allowing extra
  # chars).
  #
  SHORTURL_RE = %r{\Ahttp://(?:1link.in|4url.cc|6url.com|adjix.com|ad.vu|bellypath.com|bit.ly|bkite.com|budurl.com|canurl.com|chod.sk|cli.gs|decenturl.com|dn.vc|doiop.com|dwarfurl.com|easyuri.com|easyurl.net|ff.im|go2cut.com|gonext.org|hulu.com|hypem.com|ifood.tv|ilix.in|is.gd|ix.it|jdem.cz|jijr.com|kissa.be|kurl.us|litturl.com|lnkurl.com|memurl.com|metamark.net|miklos.dk|minilien.com|minurl.org|muhlink.com|myurl.in|myurl.us|notlong.com|ow.ly|plexp.com|poprl.com|qurlyq.com|redirx.com|s3nt.com|shorterlink.com|shortlinks.co.uk|short.to|shorturl.com|shrinklink.co.uk|shrinkurl.us|shrt.st|shurl.net|simurl.com|shorl.com|smarturl.eu|snipr.com|snipurl.com|snurl.com|sn.vc|starturl.com|surl.co.uk|tighturl.com|timesurl.at|tiny123.com|tiny.cc|tinylink.com|tinyurl.com|tobtr.com|traceurl.com|tr.im|tweetburner.com|twitpwr.com|twitthis.com|twurl.nl|u.mavrev.com|ur1.ca|url9.com|urlborg.com|urlbrief.com|urlcover.com|urlcut.com|urlhawk.com|url-press.com|urlsmash.com|urltea.com|urlvi.be|vimeo.com|wlink.us|xaddr.com|xil.in|xrl.us|x.se|xs.md|yatuc.com|yep.it|yweb.com|zi.ma|w3t.org)/.}
  def self.is_shorturl? url
    url.to_s =~ SHORTURL_RE
  end
end
