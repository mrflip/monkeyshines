require 'right_aws'
module Monkeyshines
  module ScrapeStore

    #
    # Large portions lifted from Thoughtbot's Paperclip gem.
    #
    # Amazon's S3 file hosting service is a scalable, easy place to store files for
    # distribution. You can find out more about it at http://aws.amazon.com/s3
    # There are a few S3-specific options for has_attached_file:
    # * +s3_credentials+: Takes a path, a File, or a Hash. The path (or File) must point
    #   to a YAML file containing the +access_key_id+ and +secret_access_key+ that Amazon
    #   gives you. You can 'environment-space' this just like you do to your
    #   database.yml file, so different environments can use different accounts:
    #     development:
    #       access_key_id: 123...
    #       secret_access_key: 123...
    #     test:
    #       access_key_id: abc...
    #       secret_access_key: abc...
    #     production:
    #       access_key_id: 456...
    #       secret_access_key: 456...
    #   This is not required, however, and the file may simply look like this:
    #     access_key_id: 456...
    #     secret_access_key: 456...
    #   In which case, those access keys will be used in all environments. You can also
    #   put your bucket name in this file, instead of adding it to the code directly.
    #   This is useful when you want the same account but a different bucket for
    #   development versus production.
    # * +s3_permissions+: This is a String that should be one of the "canned" access
    #   policies that S3 provides (more information can be found here:
    #   http://docs.amazonwebservices.com/AmazonS3/2006-03-01/RESTAccessPolicy.html#RESTCannedAccessPolicies)
    #   The default for Paperclip is "public-read".
    # * +s3_protocol+: The protocol for the URLs generated to your S3 assets. Can be either
    #   'http' or 'https'. Defaults to 'http' when your :s3_permissions are 'public-read' (the
    #   default), and 'https' when your :s3_permissions are anything else.
    # * +s3_headers+: A hash of headers such as {'Expires' => 1.year.from_now.httpdate}
    # * +bucket+: This is the name of the S3 bucket that will store your files. Remember
    #   that the bucket must be unique across all of Amazon S3. If the bucket does not exist
    #   Paperclip will attempt to create it. The bucket name will not be interpolated.
    #   You can define the bucket as a Proc if you want to determine it's name at runtime.
    #   Paperclip will call that Proc with attachment as the only argument.
    # * +s3_host_alias+: The fully-qualified domain name (FQDN) that is the alias to the
    #   S3 domain of your bucket. Used with the :s3_alias_url url interpolation. See the
    #   link in the +url+ entry for more information about S3 domains and buckets.
    # * +url+: There are three options for the S3 url. You can choose to have the bucket's name
    #   placed domain-style (bucket.s3.amazonaws.com) or path-style (s3.amazonaws.com/bucket).
    #   Lastly, you can specify a CNAME (which requires the CNAME to be specified as
    #   :s3_alias_url. You can read more about CNAMEs and S3 at
    #   http://docs.amazonwebservices.com/AmazonS3/latest/index.html?VirtualHosting.html
    #   Normally, this won't matter in the slightest and you can leave the default (which is
    #   path-style, or :s3_path_url). But in some cases paths don't work and you need to use
    #   the domain-style (:s3_domain_url). Anything else here will be treated like path-style.
    #   NOTE: If you use a CNAME for use with CloudFront, you can NOT specify https as your
    #   :s3_protocol; This is *not supported* by S3/CloudFront. Finally, when using the host
    #   alias, the :bucket parameter is ignored, as the hostname is used as the bucket name
    #   by S3.
    # * +path+: This is the key under the bucket in which the file will be stored. The
    #   URL will be constructed from the bucket and the path. This is what you will want
    #   to interpolate. Keys should be unique, like filenames, and despite the fact that
    #   S3 (strictly speaking) does not support directories, you can still use a / to
    #   separate parts of your file name.
    class S3Repository < Monkeyshines::Repository::Base
      attr_reader :bucket_name, :s3_host_alias, :s3_protocol

      def initialize options={}
        @s3_credentials = parse_credentials(@options[:s3_credentials])
        @bucket         = @options[:bucket]         || @s3_credentials[:bucket]
        @bucket         = @bucket.call(self) if @bucket.is_a?(Proc)
        @s3_options     = @options[:s3_options]     || {}
        @s3_permissions = @options[:s3_permissions] || 'public-read'
        @s3_protocol    = @options[:s3_protocol]    || (@s3_permissions == 'public-read' ? 'http' : 'https')
        @s3_headers     = @options[:s3_headers]     || {}
        @s3_host_alias  = @options[:s3_host_alias]
      end

      #
      # Implementation of Monkeyshines::Repository
      #

      def exists?(filename)
        s3_bucket.key(filename) ? true : false
      end

      def md5(filename)
      end

      def
      end

      #
      # s3 interface
      #

      # Use with Monkeyshines::Utils::FilenamePattern to generate urls to s3 files.
      # Ex:
      #     s3_url = FilenamePattern.new(":s3_path_url_base/path/to/file.ext", s3_repo.filename_pattern_tokens)
      #
      def filename_pattern_tokens
        { :s3_domain_url_base => "#{s3_protocol}://#{bucket_name}.s3.amazonaws.com",
          :s3_alias_url_base  => "#{s3_protocol}://#{s3_host_alias}",
          :s3_path_url_base   => "#{s3_protocol}://s3.amazonaws.com/#{bucket_name}", }
      end

      def s3
        @s3 ||= RightAws::S3.new(@s3_credentials[:access_key_id],
          @s3_credentials[:secret_access_key],
          @s3_options)
      end

      def s3_bucket
        @s3_bucket ||= s3.bucket(@bucket, true, @s3_permissions)
      end

      def parse_credentials creds
        find_credentials(creds)
      end

      def find_credentials creds
        case creds
        when File
          YAML.load_file(creds.path)
        when String
          YAML.load_file(creds)
        when Hash
          creds
        else
          raise ArgumentError, "Credentials are not a path, file, or hash."
        end
      end
      private :find_credentials

      # # Returns representation of the data of the file assigned to the given
      # # style, in the format most representative of the current storage.
      # def to_file path
      #   @queued_for_write[path] || s3_bucket.key(path(style))
      # end
      # alias_method :to_io, :to_file
      #
      # def flush_writes #:nodoc:
      #   @queued_for_write.each do |style, file|
      #     begin
      #       log("saving #{path(style)}")
      #       key = s3_bucket.key(path(style))
      #       key.data = file
      #       key.put(nil, @s3_permissions, {'Content-type' => instance_read(:content_type)}.merge(@s3_headers))
      #     rescue RightAws::AwsError => e
      #       raise
      #     end
      #   end
      #   @queued_for_write = {}
      # end
      #
      # def flush_deletes #:nodoc:
      #   @queued_for_delete.each do |path|
      #     begin
      #       log("deleting #{path}")
      #       if file = s3_bucket.key(path)
      #         file.delete
      #       end
      #     rescue RightAws::AwsError
      #       # Ignore this.
      #     end
      #   end
      #   @queued_for_delete = []
      # end

    end

  end
end
