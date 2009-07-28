require 'right_aws'
module Monkeyshines
  module Repository
    class Base

      def exists?(key)
      end
      alias_method :include?, :exists?

      def put key, val
      end

      def get key
      end

      def open
      end

      def close
      end

      def uri key
      end

      def md5 key
        metadata key, :md5
      end
      alias_method :checksum, :md5

      def size key
      end

      def timestamp key
      end

      # By default,
      #     size+timestamp-md5
      # Ex:
      #     1251777182+20090222121200-577416a26499f6facf45973298be5276
      def version_id
        "#{size}+#{timestamp}-#{md5}"
      end

      CACHED_METADATA = {}
      def metadata key, datum=nil
        attrs = CACHED_METADATA[key] || get_metadata(key, datum)
        datum ? attrs[datum] : attrs
      end

      # fetch
      def get_metadata key, datum=nil
        #
      end

    end
  end
end
