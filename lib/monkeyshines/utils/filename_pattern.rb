require 'wukong/utils/filename_pattern'

module Monkeyshines
  module Utils
    class FilenamePattern < Wukong::Utils::FilenamePattern
      # def replace token, token_vals
      #   token_vals = token_vals.reverse_merge :revdom_prefix => '_revdom_prefix', :revdom => '_revdom'
      #   super token, token_vals
      # end
    end
  end
end
