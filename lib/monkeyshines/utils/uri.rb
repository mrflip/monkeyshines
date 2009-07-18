require 'addressable/uri'
module Addressable
  #
  # Add the #scrubbed and #revhost calls
  #
  class URI
    #
    # These are illegal but *are* found in URLs. We're going to let them through.
    # Note that ' ' space is one of the tolerated miscreants.
    #
    URL_ILLEGAL_BUT_WHATEVER_DOOD_CHARS = '\{\}\| \^\`'
    #
    # These are all the characters that belong in a URL
    #
    PERMISSIVE_SCRUB_CHARS =
      URL_ILLEGAL_BUT_WHATEVER_DOOD_CHARS            +
      Addressable::URI::CharacterClasses::UNRESERVED +
      Addressable::URI::CharacterClasses::RESERVED   + '%'

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
      return url if url.blank?
      url.gsub(/[^#{PERMISSIVE_SCRUB_CHARS}]+/) do |sequence|
        sequence.unpack('C*').map{ |c| ("%%%02x"%c).upcase }.join("")
      end
    end

    #
    # +revhost+
    # the dot-reversed host:
    #   foo.company.com => com.company.foo
    #
    def revhost
      return host unless host =~ /\./
      host.split('.').reverse.join('.')
    end

    #
    # +uuid+  -- RFC-4122 ver.5 uuid; guaranteed to be universally unique
    #
    # See http://www.faqs.org/rfcs/rfc4122.html
    #
    # You ned to require "monkeyshines/utils/uuid" as well...
    #
    def url_uuid
      UUID.sha1_create(UUID_URL_NAMESPACE, self.normalize.to_s)
    end
  end
end
