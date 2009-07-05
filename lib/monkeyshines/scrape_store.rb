require 'fileutils'; include FileUtils

module TwitterFriends
  module Scrape

    class TarScrapeStore
      attr_accessor :tar_filename
      def initialize tar_filename
        self.tar_filename = tar_filename
      end

      # Base path for temporary extraction
      LOCAL_EXTRACT_DIR = '/workspace/flip/data/ripd'
      #
      # Where to extract files temporarily
      #
      def extract_dir
        LOCAL_EXTRACT_DIR + '/' + File.basename(tar_filename).gsub(/\..*$/, '')
      end

      def listing
        `hdp-cat #{tar_filename} | tar tjvf - | egrep '\.json$'`.split("\n")
      end

      def target
        case
        when m = %r{ripd-(\d{8})-(\d\d)-([\w-]+)}.match(tar_filename)
          scrape_session, hour, resource_path = m.captures
          "_com/_tw/com.twitter/_%s/_%s/%s" % [scrape_session, hour, resource_path.gsub(/-/, '/')]
        when m = %r{public_timeline-(\d{6})-(\d\d)}.match(tar_filename)
          scrape_session, day = m.captures
          "public_timeline/%s/%s" % [scrape_session, day]
        else raise "Can't grok #{tar_filename}"
        end
      end

      def extracted?
        File.exists?(extract_dir + '/' + target)
      end

      def extract!
        $stderr.puts [tar_filename, extracted?, extract_dir, target].inspect
        if ! extracted?
          mkdir_p extract_dir
          cd extract_dir do
            `hdp-cat #{tar_filename} | tar xjfk - --mode 666`
          end
        end
      end

      def extracted_files
        cd extract_dir do
          return Dir['**/*.json']
        end
      end

      def contents &block
        cd extract_dir do
          extracted_files.each do |scraped_filename|

            # Grok filename
            scraped_file = ScrapedFile.new_from_filename(scraped_filename, nil) or next

            # extract file's contents
            cnts = nil
            File.open(scraped_filename) do |file|
              cnts = file.read
              cnts = cnts.gsub(/\s+\z/, '').gsub(/[\t\r\n]+/, ' ') if cnts
            end

            # process
            next if (! cnts) || cnts.empty?
            yield scraped_file, cnts
          end
        end
      end
    end



    # TAR_RE = %r{(public_timeline)-([\d-]+)(?:-partial)?\.tar\.bz2}
    # def tar_contents_dir tar_filename
    #   m = TAR_RE.match(tar_filename) or raise "Can't grok archive filename '#{tar_filename}'"
    #   resource, scrape_session = m.captures
    #   resource.gsub!(/\-/, '/') ; scrape_session.gsub!(/\-/, '/')
    #   "#{resource}/#{scrape_session}"
    # end
  end
end
