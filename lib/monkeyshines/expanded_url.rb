require 'net/http'
require 'addressable/uri'
#
#
# SELECT 'expanded_url', short_url, IFNULL(dest_url,""), IFNULL(scraped_at,"")
#   FROM expanded_urls
#   INTO OUTFILE '~/ics/pool/social/network/twitter_friends/fixd/dump/expanded_urls-20090113.tsv'  ;
#
#

module TwitterFriends
  module Scrape
    include TwitterFriends::StructModel::ModelCommon

    class ExpandedUrl < Struct.new(:src_url, :dest_url, :scraped_at)
      # src_url uniquely identifies us
      def num_key_fields() 1  end

      #
      # Get the redirect location... don't follow it, just request and store it.
      #
      def fetch_dest_url! options={ }
        return unless dest_url.blank? && scraped_at.blank?
        options = options.reverse_merge :sleep => 1
        fix_src_url!
        begin
          # look for the redirect
          raw_dest_url = Net::HTTP.get_response(URI.parse(src_url))["location"]
          self.dest_url = self.class.scrub_url(raw_dest_url)
          sleep options[:sleep]
        rescue Exception => e
          nil
        end
        self.scraped_at = TwitterFriends::StructModel::ModelCommon.flatten_date(DateTime.now) if self.scraped_at.blank?
      end

      #
      # These are all the characters that belong in a URL
      #
      RE_URL_SANE_CHARS =
        Addressable::URI::CharacterClasses::UNRESERVED +
        Addressable::URI::CharacterClasses::RESERVED   + '%'
      #
      # These are illegal but *are* found in URLs. We're going to let them through.
      # Note that ' ' space is one of the tolerated miscreants.
      #
      RE_URL_ILLEGAL_BUT_WHATEVER_DOOD_CHARS = '\{\}\|\^\` '
      #
      # Replace all url-insane characters by their %encoding. We don't really
      # care here whether the URLs do anything: we just want to remove stuff that
      # absosmurfly don't belong.
      #
      # This code is stolen from Addressable::URI, which unfortunately has a bug
      # in exactly this method (fixed here). (http://addressable.rubyforge.org)
      # Note that we are /not/ re-encoding characters like '%' -- it's assumed
      # that the url is encoded, but perhaps poorly.
      #
      # In practice the illegal characters most often seen are those in
      # RE_URL_ILLEGAL_BUT_WHATEVER_DOOD_CHARS plus
      #   <>"\t\\
      #
      def self.scrub_url url
        url.gsub(/[^#{RE_URL_SANE_CHARS+RE_URL_ILLEGAL_BUT_WHATEVER_DOOD_CHARS}]/) do |sequence|
          sequence.unpack('C*').map{ |c| ("%%%02x"%c).upcase }.join("")
        end
      end

      #
      # Handle some known edge cases / simplifications with short urls
      #
      def fix_src_url!
        fix_isgd_url!
      end
      #
      # is.gd urls use a terminal '-' to indicate 'preview' -- but
      # we want the destination, so strip that.
      #
      def fix_isgd_url!
        self.src_url.gsub!(%r{(http://is.gd/\w+)[-/]}, '\1')
      end

      #
      # The major shortening services
      #
      # Do any of the mainstream shorteners use in-band characters besides \w
      # alphanum and - dash?  (idek.net uses a ~ and pastoid.com a + but they
      # are not popular enough to justify the annoyance of allowing extra
      # chars).
      #
      TINY_URLISHES_RE = %r{\Ahttp://(
        | tinyurl.com                   # 4969626
        | is.gd                         #  406718
        | bit.ly                        #  298590
        | twurl.nl                      #  169796
        | snipurl.com                   #  107961
        | tr.im                         #   38793
        | snurl.com                     #   37576
        | snipr.com                     #   26897
        | jijr.com                      #   20965
        | cli.gs                        #   19700
        | budurl.com                    #   19402
        | xrl.us                        #   11621
        # | tiny.cc                     #    9140  # tiny.cc borks scraper
        | zi.ma                         #    8148
        | s3nt.com                      #    6922
        | ow.ly                         #    6848
        | poprl.com                     #    6666
        | piurl.com                     #    5262
        | ur1.ca                        #    4435
        | short.to                      #    4105
        | urlenco.de                    #    4087
        | zz.gd                         #    4045
        | rubyurl.com                   #    3766
        | uris.jp                       #    2749
        | ub0.cc                        #    2607
        | twurl.cc                      #    2545
        | moourl.com                    #    2280
        | rurl.org                      #    2271
        | url.ie                        #    2156
        )/([\w\-]+)}ix
      def self.match_tinyurlish url
        m = TINY_URLISHES_RE.match(url) or return
        host, path = m.captures
        "http://#{host.downcase}/#{path}"
      end

      #
      # If the base part looks like a tinyurlish, return an instantiated object
      # Otherwise, return nil
      #
      # This will happily turn
      #   http://tinyurl.com/aaASDF/A-BUNCH_OF_BOGOSITY
      # into just the http://tinyurl.com/aaASDF
      #
      def self.new_if_tinyurlish url
        src_url = match_tinyurlish(url) or return
        new(src_url, nil, nil)
      end

    end
  end
end

#
# Frequency of host part from ~ 6M URLs.
# Just a rough guide -- don't go launchin' yer SEO campaign using these numbers.
#
# 4969626 tinyurl.com
#  406718 is.gd
#  298590 bit.ly
#  169796 twurl.nl
#  107961 snipurl.com
#   38793 tr.im
#   37576 snurl.com
#   26897 snipr.com
#   20965 jijr.com
#   19700 cli.gs
#   19402 budurl.com
#   11621 xrl.us
#    9140 tiny.cc
#    8148 zi.ma
#    6922 s3nt.com
#    6848 ow.ly
#    6666 poprl.com
#    5262 piurl.com
#    4435 ur1.ca
#    4105 short.to
#    4087 urlenco.de
#    4045 zz.gd
#    3766 rubyurl.com
#    2749 uris.jp
#    2607 ub0.cc
#    2545 twurl.cc
#    2280 moourl.com
#    2271 rurl.org
#    2156 url.ie
#
#  235192 ff.im
#   82062 bkite.com
#   81792 blip.fm
#   53928 ping.fm
#   28826 loopt.us
#   13724 ad.vu
#    8438 tgr.me
#    8418 adjix.com
#    5061 www.url.inc
#         pastoid.com
#
#  339312 twitpic.com
#   28282 rsstotwitter.com
#   26641 twitter.com
#   22263 www.nicovideo.jp
#   21897 www.flickr.com
#   20910 live.nicovideo.jp
#   18604 book.akahoshitakuya.com
#   16674 movapic.com
#   15844 jobfeedr.com
#   15049 u.mavrev.com
#   14537 f.hatena.ne.jp
#   14454 www.last.fm
#   12003 be
#   11548 www.desktoptopia.com
#   10712 raptr.com
#   10340 hellotxt.com
#   10266 deals.clhmedia.com
#    9910 mrtweet.net
#    9818 echos.tumblr.com
#    9378 echomas.tumblr.com
#    9330 flickr.com
#    8695 weather.livedoor.com
#    8525 d.hatena.ne.jp
#    7524 radiopopbitch.com
#    7501 qik.com
#    7161 aweber.com
#    7086 www.myspace.com
#    6990 activerain.com
#    6811 ruwt.tv
#    6722 bbc.co.uk
#    6344 www.amazon.com
#    6328 photohito.com
#    6142 techwatching.com
#    6117 kexplorer.com
#    6009 EzineArticles.com
#    5964 www.squidoo.com
#    5929 news.bbc.co.uk
#    5756 mobypicture.com
#    5489 www.youtube.com
#    5454 robotbling.com
#    5433 www.timesoftheinternet.com
#    5182 www.blogtv.com
#    5105 tiny12.tv
#    5084 www.imdb.com
#    4894 www.ustream.tv
#    4800 vimeo.com
#    4796 yes.com
#    4665 5ver.com
#    4596 www.absurdtrivia.com
#    4585 twittgroups.com
#    4525 funp.com
#    4472 en.wikipedia.org
#    4431 hypem.com
#    4313 anond.hatelabo.jp
#    4222 twitxr.com
#    4045 twitter.grader.com
#    3987 yourinternetradio.com
#    3976 TwitPWR.com
#    3964 sfbay.craigslist.org
#    3876 x.imeem.com
#    3757 www.invertia.com
#    3556 timesurl.at
#    3531 www.jb.man.ac.uk
#    3528 bossalive.com
#    3410 buzztter.com
#    3337 www.accuweather.com
#    3324 drawr.net
#    3285 xkcd.com
#    3270 maps.google.com
#    3243 tobtr.com
#    3182 www.cnn.com
#    3180 www.stickam.com
#    3177 www.dailymugshot.com
#    3163 r.reuters.com
#    2963 148apps.com
#    2885 unvlog.com
#    2853 tweetwasters.com
#    2778 eloglife.net
#    2758 dihitt.com.br
#    2751 openzap.com
#    2727 blip.tv
#    2699 www.sailingxperience.com
#    2682 eepics.com
#    2638 blog.livedoor.jp
#    2552 iphone.robotbling.com
#    2528 phodroid.com
#    2490 twitter.digsby.com
#    2420 plazes.com
#    2391 www.google.com
#    2311 www.msnbc.msn.com
#    2228 gamerdna.com
#    2227 gyazo.com
#    2197 www.vimeo.com
#    2184 entertonement.com
#    2157 c2.koukokukaigisitsu.com
#

      # def spread_key() self.src_url[-3..-1] end
      # def output_form spread=false
      #   spread ? ("%s-%s\t%s"%[resource_name, spread_key, to_tsv]) : super()
      # end
