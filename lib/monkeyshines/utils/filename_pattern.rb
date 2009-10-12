module Monkeyshines
  module Utils
    class FilenamePattern
      # Memoize recognizer regexps
      RECOGNIZER_REGEXPS = {}
      # the filename pattern, e.g. 'ripd/:handle/:date/:handle+:timestamp-:pid-:hostname.tsv'
      attr_accessor :pattern
      # custom token replacements
      attr_accessor :token_val_defaults
      # the base regexp pattern used to recognize templated products.
      attr_accessor :recognizer_pattern

      DEFAULT_PATTERN_STR = ":dest_dir/:handle_prefix/:handle/:date/:handle+:timestamp-:pid-:hostname.tsv"

      def initialize pattern, token_val_defaults={}
        self.pattern = pattern
        self.token_val_defaults    = token_val_defaults
      end

      #
      # walk through pattern, replacing tokens (eg :time or :pid) with the
      # corresponding value.
      #
      def make token_vals={}
        token_vals = token_val_defaults.merge token_vals
        token_vals[:timestamp] ||= Time.now.utc.strftime("%Y%m%d%H%M%S")
        val = pattern.gsub(/:(\w+)/){ replace($1, token_vals)  }
        val
      end

      def to_s token_vals={}
        make token_vals
      end

      #
      # walk through pattern, constructing a regexp for parsing a templated
      # product of that pattern
      #
      # It's undefined if a token is repeated inconsistently, eg recognizing
      # '20090426012345/foo-20070707070707' with ':timestamp/:handle-:timestamp'
      # It's harmless to have a token that is repeated, but always identically.
      #
      def make_recognizer token_regexps={}
        return RECOGNIZER_REGEXPS[pattern] if RECOGNIZER_REGEXPS[pattern]
        tokens        = []
        recognizer    = recognizer_pattern.gsub(/:(\\\{\w+\\\}|\w+)/) do
          tok = $1.gsub(/\W/,'')
          tokens << tok.to_sym
          '('+recognize_replace(tok, token_regexps)+')'
        end
        RECOGNIZER_REGEXPS[pattern] = [Regexp.new(recognizer), tokens]
      end

      #
      # substitute for token
      #
      def replace token, token_vals
        token = token.to_sym
        return token_vals[token] if token_vals.include? token
        case token
        when :pid           then pid
        when :hostname      then hostname
        when :handle        then token_vals[:handle] || Monkeyshines::CONFIG[:handle]
        when :handle_prefix then token_vals[:handle].to_s[0..5]
        when :timestamp     then token_vals[:timestamp]
        when :date          then token_vals[:timestamp][ 0..7]
        when :time          then token_vals[:timestamp][ 8..13]
        when :hour          then token_vals[:timestamp][ 8..9]
        when :min           then token_vals[:timestamp][10..11]
        when :sec           then token_vals[:timestamp][12..13]
        else
          raise "Don't know how to encode token #{token} #{token_vals[token]}"
        end
      end

      # Memoized: the hostname for the machine running this script.
      def hostname
        @hostname ||= ENV['HOSTNAME'] || `hostname`
      end
      # Memoized: the Process ID for this invocation.
      def pid
        @pid      ||= Process.pid
      end

      # Characters deemed safe in a filename;
      SAFE_CHARS = 'a-zA-Z0-9_\-\.\+\/\;'
      def self.sanitize str
        str.gsub(%r{[^#{SAFE_CHARS}]+}, '-')
      end

      # The base regexp pattern used to recognize templated products.
      # By default, it's just the regexp-escaped version of this pattern,
      # rooted on the right hand side (the end of the pattern matches the end of
      # the string)
      def recognizer_pattern
        @recognizer_pattern ||= Regexp.escape(pattern)+'\z'
      end

      def recognize_replace token, token_vals
        token = token.to_sym
        return token_vals[token] if token_vals.include? token
        case token
        when :pid           then '\d{1,5}'
        when :hostname      then '[a-zA-Z][a-zA-Z0-9\-\.]*[a-zA-Z0-9]'
        when :handle        then '[\w\-\.]+'
        when :handle_prefix then '[\w\-\.]+'
        when :timestamp     then '\d{14}'
        when :date          then '\d{8}'
        when :time          then '\d{6}'
        when :hour          then '\d{2}'
        when :min           then '\d{2}'
        when :sec           then '\d{2}'
        when :ext           then '[a-zA-Z0-9\.]+'
        when :any_id        then '\w+'
        else
          raise "Don't know how to encode token #{token} #{token_vals[token]}"
        end
      end

      def recognize str, token_regexps={}
        recognizer, tokens = make_recognizer token_regexps
        unless m = recognizer.match(str)
          warn "Can't match #{recognizer} against #{str}"
          return
        end
        Hash.zip(tokens, m.captures)
      end

      def unrecognize
        RECOGNIZER_REGEXPS.delete pattern
      end
    end
  end
end
