require 'uuidtools'
class UUID

  #
  # A string suitable for using as a path name --
  #
  # Ex.
  #   urn:uuid:3c0dce44-80a8-11dd-a897-001ff35a0a8b =>
  #   urn_uuid/3c0dce44/80a8/11dd/a897/001ff35a0a8b
  #
  # It's well possible there are more perspicacious choices for points to split
  # the string, but until we hit that limit this'll do.
  #
  def to_path
    'urn_uuid/' + to_s.gsub(/[\:\-]/,'/')
  end

  def self.hex_to_str str
    /([\da-f]{8})([\da-f]{4})([\da-f]{4})([\da-f]{4})([\da-f]{12})/.match(str).captures.join '-'
  end


  def self.parse_hex str
    parse(UUID.hex_to_str(str))
  end

  # Overrides UUIDTools -- force 32 hex digits (leading zeros)
  def hexdigest
    "%032x" % self.to_i
  end

end
