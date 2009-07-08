require 'imw/utils/uuid'
require 'addressable/uri'
module Addressable
  #
  # Add the #scrubbed and #revhost calls
  #
  class URI
    SAFE_CHARS      = %r{a-zA-Z0-9\-\._!\(\)\*\'}
    PATH_CHARS      = %r{#{SAFE_CHARS}\$&\+,:=@\/;}
    RESERVED_CHARS  = %r{\$&\+,:=@\/;\?\%}
    UNSAFE_CHARS    = %r{\\ \"\#<>\[\]\^\`\|\~\{\}}
    HOST_HEAD     = '(?:[a-z0-9\-]+\.)+'
    HOST_TLD      = '(?:[a-z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|jobs|museum)'

    def host_valid?
      !!(host =~ %r{\A#{HOST_HEAD}#{HOST_TLD}\z}i)
    end
    def path_valid?
      !!(path =~ %r{\A[#{PATH_CHARS}%]*\z})
    end
    def simple_connection_part?
      ( ['http', nil].include?(scheme) &&
        [80,     nil].include?(port) &&
        (self.to_hash.values_at(:password, :user).join.blank?) )
    end

    #
    # Does this look like a
    #
    def simple?
      host_valid? && path_valid? && simple_connection_part?
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
    # See
    #   http://www.faqs.org/rfcs/rfc4122.html
    #
    def url_uuid
      UUID.sha1_create(UUID_URL_NAMESPACE, self.normalize.to_s)
    end
  end
end
