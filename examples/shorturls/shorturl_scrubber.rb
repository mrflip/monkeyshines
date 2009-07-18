module ShorturlScrubber
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
  RE_URL_ILLEGAL_BUT_WHATEVER_DOOD_CHARS = '\{\}\| \^\`'
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
    scrubbed = false
    scrubbed_url = url.gsub(/[^#{RE_URL_SANE_CHARS+RE_URL_ILLEGAL_BUT_WHATEVER_DOOD_CHARS}]/) do |sequence|
      sequence.unpack('C*').map{ |c| ("%%%02x"%c).upcase }.join("")
      scrubbed = true
    end
    warn [url, scrubbed_url].inspect if scrubbed
    scrubbed_url
  end

end
