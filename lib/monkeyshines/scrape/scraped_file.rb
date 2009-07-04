require 'rubygems'
require 'addressable/uri'

module TwitterFriends
  module Scrape
    #
    # Info about a raw scraped file. Once fresh off the servers, now forever frozen
    # in time, monument to a bygone age.
    #
    #
    class ScrapedFile < Struct.new(
        :scrape_session, :context, :identifier, :page,
        :scraped_at, :filename, :size, :moreinfo, :scrape_store )
      include ModelCommon
      include TwitterApi
      attr_accessor :bogus

      def keyspace_spread_resource_name
        case
        when self.bogus          then :scraped_file_bogus
        when self.size.to_i == 0 then :scraped_file_zerolen
        else                          'scraped_file-%s-%s' % [scraped_at[0..7], context] end # , scraped_at[8..9]
      end

      def encode_path_part path_part
        path_part = Addressable::URI.encode_component(path_part, "a-zA-Z0-9_\\.\\-") || ""
        path_part.gsub(/^_/, "%5F")
      end

      #
      # Filename for the scraped URI
      #
      def gen_scraped_filename
        file_part = "%s.json%%3Fpage%%3D%s+%s+%s.json" % [
          encode_path_part(identifier), page, scraped_at, encode_path_part(moreinfo)]
        self.filename = [ filename_host_part, filename_tier_part, resource_path, file_part ].join("/")
      end
      # def old_scraped_filename
      #   old_filename_tier_part =
      #   self.filename = [
      #     filename_host_part, filename_tier_part, resource_path,
      #     "#{identifier}.json%3Fpage%3D#{page}+#{scraped_at}.json" ].join("/")
      # end
      def filename_host_part
        '_com/_tw/com.twitter'
      end
      def filename_tier_part
        day_part, hour_part = /(\d{8})(\d{2})/.match(scraped_at).captures
        "_%s/_%s" %[day_part, hour_part]
      end

      #
      # Pull file info from a flat listing.
      # individually querying for file metadata violates idempotency,
      # We instead freeze scraped directories, take a static listing
      # and draw metadata from there.
      #
      # tar tvjf foo.tar.bz2
      # -rw-r--r-- flip/flip       134 2008-12-23 17:29 path1/path2/foo.bar
      # ls -l path1/path2/foo.bar
      # -rw-r--r-- 1 flip wheel  67743 2008-12-24 13:25 path1/path2/foo.bar
      def self.new_from_ls_line line, format=:tar
        vals = line.chomp.split(/\s+/)
        case format
        when :tar then mode,    owner_group,  size, dt, tm, filename = vals
        when :ls  then mode, _, owner, group, size, dt, tm, filename = vals
        else raise "Need a format string: got #{format.inspect}"
        end
        if !filename then warn "Ill-formed 'ls' line #{line}"; return nil ; end
        self.new_from_filename(filename, size) or return nil
      end

      #
      # Format for ripd urls on disk
      #
      # This will change after the great renaming
      #
      GROK_FILENAME_RE       = %r{com\.twitter/_(\d{8}/_\d{2})/([\w/]+)/((?:%5F|\w)\w*)\.json%3Fpage%3D(\d+)\+u(\d{10})\+d(\d{14})\.json}
      GROK_OLD_FILENAME_RE   = %r{com\.twitter/_(\d{8}/_\d{2})/([\w/]+)/((?:%5F|\w)\w*)\.json%3Fpage%3D(\d+)\+(\d{8}-\d{6})\.json}
      GROK_BOGUS_FILENAME_RE = %r{com\.twitter/_(\d{8}/_\d{2})/([\w/]+)/(.*)\.json%3Fpage%3D(\d+)(?:[^\+]*?)(?:\+u?([\d\-]+))?\+d?([\d\-]+)\.json}
      GROK_PUBLIC_TIMELINE_FILENAME_RE = %r{public_timeline/(\d{6}/\d\d/\d\d)/public_timeline-(\d{8}-\d{6}).json}
      #
      # Instantiate from filename
      #
      def self.new_from_filename filename, size
        case
        when m = GROK_FILENAME_RE.match(filename)
          scrape_session, resource, moreinfo, page, identifier, scraped_at = m.captures
          identifier = Addressable::URI.unencode_component(identifier)
          context    = context_for_resource(resource)
        when m = GROK_OLD_FILENAME_RE.match(filename)
          scrape_session, resource, moreinfo, page, scraped_at = m.captures
          moreinfo   = Addressable::URI.unencode_component(moreinfo)
          identifier = ''
          context    = context_for_resource(resource)
        when m = GROK_BOGUS_FILENAME_RE.match(filename)
          scrape_session, resource, moreinfo, page, scraped_at = m.captures
          moreinfo   = Addressable::URI.unencode_component(moreinfo)
          identifier = ''
          context    = context_for_resource(resource)
          bogus      = true
        when m = GROK_PUBLIC_TIMELINE_FILENAME_RE.match(filename)
          scrape_session, scraped_at, *_ = m.captures
          scraped_at.gsub!(/-/, '')
          identifier = scraped_at
          context, resource, page, moreinfo = ['public_timeline', 'public_timeline', 1, '']
        when
          scrape_session, resource, identifier, page, scraped_at = m.captures
        else
          warn "Can't grok filename #{filename}";
          scrape_session, resource, identifier, page, scraped_at = []
          bogus      = true
        end
        #
        # extract field values
        # instantiate
        moreinfo ||= ''
        scraped_at.gsub!(/-/, '') if scraped_at
        scraped_file = self.new scrape_session, context, identifier, page, scraped_at, filename, size, moreinfo
        scraped_file.bogus = bogus
        scraped_file
      end
    end
  end
end
