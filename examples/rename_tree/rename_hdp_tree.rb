#!/usr/bin/env ruby
$: << ENV['HOME']+'/ics/rubygems/trollop-1.14/lib'
$: << ENV['HOME']+'/ics/rubygems/log4r-1.0.5/src'
ENV['WUKONG_PATH'].split(":").each{|dir| $: << dir } if ENV['WUKONG_PATH']

require "monkeyshines/utils/logger"
require "monkeyshines/utils/filename_pattern.rb"; include Monkeyshines::Utils
require 'wukong'
require 'wukong/logger'
require 'fileutils'
require 'trollop'
Monkeyshines.logger = Wukong.logger

#
# This script demonstrates the use of FilenamePattern.
#
# The details are meaningless (it's a throwaway script I used to move to a more
# unified naming scheme for scraped files), but I think it nicely demonstrates
# how useful the FilenamePattern class can be.
#

opts = Trollop::options do
  opt :go,      "actually do rename (otherwise do a dry run)"
end

# The tree to walk
RIPD_ROOT = 'ripd'

'tw0604/bundled/bundled_bundled_20090623/bundle+20090623010206.scrape.tsv'

#
# Old files to rename
#
old_filename_pats = {
  'tw0227/bundled/bundled_bundled_*/*.scrape.tsv' =>
    ':any_id/bundled/bundled_bundled_:date/bundle+:timestamp.scrape.:ext',
}

#
# How to template new filename
#
new_token_defaults = {
  :dest_dir => RIPD_ROOT,
  :pid      => '0',
  :hostname => 'old',
  :handle   => 'com.twitter'
}
new_filename_pat = FilenamePattern.new(
  ':dest_dir/:handle_prefix/:handle/:date/:handle+:timestamp-:pid-old.:ext', new_token_defaults)

MADE_DIR = { }
#
# Rename with logging and without overwriting
#
def rename_carefully old_file, new_filename, do_it=false
  Wukong.logger.info "%s%-87s\t=> %s" % [do_it ? "" : "DRY RUN ", old_file.path, new_filename]
  return unless do_it
  dirname = File.dirname(new_filename)
  if !MADE_DIR[dirname] then Wukong::Dfs::HFile.mkdir_p(dirname) ; MADE_DIR[dirname] = true ; end
  old_file.mv new_filename
end

#
# Do this thing
#
old_filename_pats.each do |files_to_rename, old_filename_pat_str|
  old_filename_pat = FilenamePattern.new(old_filename_pat_str)
  Monkeyshines.logger.info "Renaming files matching #{files_to_rename}"
  Wukong::Dfs.list_files(files_to_rename)[0..2].each do |hdfs_file|
    filename_tokens = old_filename_pat.recognize(hdfs_file.path) or next
    new_filename = new_filename_pat.make(filename_tokens)
    rename_carefully hdfs_file, new_filename, opts[:go]
  end
end
