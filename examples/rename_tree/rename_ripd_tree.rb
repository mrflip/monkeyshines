#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../../lib'
$: << ENV['HOME']+'/ics/rubygems/trollop-1.14/lib'
$: << ENV['WUKONG_PATH'] if ENV['WUKONG_PATH']
require "monkeyshines/utils/logger"
require "monkeyshines/utils/filename_pattern.rb"; include Monkeyshines::Utils
require 'wukong/extensions/hash'
require 'fileutils'
require 'trollop'

#
# This script demonstrates the use of FilenamePattern.
#
# The details are meaningless (it's a throwaway script I used to move to a more
# unified naming scheme for scraped files), but I think it nicely demonstrates
# how useful the FilenamePattern class can be.
#

opts = Trollop::options do
  opt :dry_run,      "perform a dry run (no actions are taken)"
end

# The tree to walk
RIPD_ROOT = '/data/ripd'

#
# Old files to rename
#
old_filename_pats = {
  RIPD_ROOT+'/com.tw/com.twitter/bundled/_200*/**/*' =>
    RIPD_ROOT+'/com.tw/:handle/bundled/_:date/_:hour/bundle+:timestamp.scrape.:ext',
  # RIPD_ROOT+'/com.tw/com.twitter.stream/hosebird-*' =>
  #   RIPD_ROOT+'/com.tw/:handle/hosebird-:date-:time.:ext',
  # RIPD_ROOT+'/com.tw/com.twitter.search/*/com.twitter.search+*[^r].tsv' =>
  #   RIPD_ROOT+'/com.tw/:handle/:date/:handle+:timestamp-:pid.:ext'
}

#
# How to template new filename
#
new_token_defaults = {
  :dest_dir =>   RIPD_ROOT,
  :pid      => '0',
  :hostname => 'old',
}
new_filename_pat = FilenamePattern.new(
  ':dest_dir/:handle_prefix/:handle/:date/:handle+:timestamp-:pid-:hostname.:ext', new_token_defaults)

#
# Rename with logging and without overwriting
#
def rename_carefully old_filename, new_filename, dry_run=false
  if File.exists?(new_filename) then Log.warn "Cowardly refusing to overwrite #{new_filename} from #{old_filename}" ; next ; end
  Log.info "%s%-60s \t=> %s" % [dry_run ? 'DRY RUN - ' : '', old_filename, new_filename]
  return if dry_run
  FileUtils.mkdir_p File.dirname(new_filename)
  FileUtils.mv old_filename, new_filename
end

def fix_filename_tokens! filename_tokens
  if (!filename_tokens[:timestamp]) && (filename_tokens[:date] || filename_tokens[:time])
    filename_tokens[:timestamp] = "%s%s" % [filename_tokens[:date], filename_tokens[:time]]
  end
end

#
# Do this thing
#
old_filename_pats.each do |files_to_rename, old_filename_pat_str|
  old_filename_pat = FilenamePattern.new(old_filename_pat_str)
  Log.info "Renaming files matching #{files_to_rename}"
  Dir[files_to_rename].sort.each do |old_filename|
    next unless File.file?(old_filename)
    filename_tokens = old_filename_pat.recognize(old_filename) or next
    fix_filename_tokens! filename_tokens
    new_filename = new_filename_pat.make(filename_tokens)
    rename_carefully old_filename, new_filename, opts[:dry_run]
  end
end

# example_str = '/data/ripd/_com/_tw/com.twitter/bundled/_20090224/_18/bundle+20090224180354.scrape.tsv.bz2'
# p [old_filename_pat.pattern, old_filename_pat.make_recognizer(old_token_vals), old_filename_pat.recognize(example_str)]
