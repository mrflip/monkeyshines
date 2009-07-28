#!/usr/bin/env ruby19
$: << ENV['HOME']+'/ics/rubygems/trollop-1.14/lib'
$: << ENV['HOME']+'/ics/rubygems/log4r-1.0.5/src'
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
  opt :root,    "base dir to move (tw0227, etc)", :required => true, :type => String
  opt :go,      "actually do rename (otherwise do a dry run)"
end

# The tree to walk
RIPD_ROOT = '/user/flip/ripd'

#
# Old files to rename
#
old_filename_pats = {
  # "/user/flip/#{opts[:root]}/bundled/bundled_bundled_*/*.scrape.tsv" =>
  #   ':any_id/bundled/bundled_bundled_:date/bundle+:timestamp.scrape.:ext',
  # "/user/flip/#{opts[:root]}/bundled/bundled_fff_*/*fff_*-0*" => {
  #   :patt => ':any_id/bundled/bundled_fff_:date-:any_id/:{flavor}_:date-:segment',
  #   :toks => { :ext => 'tsv' } }
  # "/user/flip/#{opts[:root]}/bundled/bundled_bundled_*/bundled-_20*.tsv" => {
  #   :patt => ':any_id/bundled/bundled_bundled_:date/bundled-_:date.:ext',
  #   :toks => { :flavor => 'bundled', :time => '000000' } }
  # "/user/flip/#{opts[:root]}/bundled/bundled_idok_*/*idok_*-0*" => {
  #   :patt => ':any_id/bundled/bundled_idok_0126_pt_0215-:any_id/:{flavor}_0126_pt_0215-:segment',
  #   :toks => { :ext => 'tsv', :date => '20090215', :flavor => 'bundled_idok' } }
  # "/user/flip/#{opts[:root]}/bundled/bundled_bundled_*/bundled-_*.tsv" =>
  #   ':any_id/bundled/bundled_bundled_:date/bundled-_:date.:ext',
  # '/user/flip/ripd/com.twitter.stream/hosebird-*' =>
  #   '/user/flip/ripd/:handle/hosebird-:date-:time.:ext',
  # "/user/flip/#{opts[:root]}/bundled/bundled_public_timeline_*/bundled_public_timeline_*.tsv" => {
  #   :patt => ':any_id/bundled/bundled_public_timeline_:date/bundled_public_timeline_:date.:ext',
  #   :toks => { :hostname => 'old+timeline' } }
  # "/user/flip/#{opts[:root]}/bundled/bundled_public_timeline_*/bundled_public_timeline_*[0-9]" => {
  #   :patt => ':any_id/bundled/bundled_public_timeline_:date/bundled_public_timeline_:date',
  #   :toks => { :hostname => 'old+timeline', :ext => 'tsv' } }
  "/user/flip/#{opts[:root]}/bundled/bundled_public_timeline_*/part-*[0-9]" => {
    :patt => ':any_id/bundled/bundled_public_timeline_:date/part-:segment',
    :toks => { :flavor => 'timeline', :ext => 'tsv' } }
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
  ':dest_dir/:handle_prefix/:handle/:date/:handle+:timestamp-:pid-:hostname+:flavor.:ext', new_token_defaults)

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
old_filename_pats.each do |files_to_rename, old_filename_rule|
  Monkeyshines.logger.info "Renaming files matching #{files_to_rename}"
  if old_filename_rule.is_a? Hash
    old_filename_pat = FilenamePattern.new(old_filename_rule[:patt])
    more_toks = old_filename_rule[:toks] || { }
  else
    old_filename_pat = FilenamePattern.new(old_filename_rule)
    more_toks = { }
  end
  #
  # List files and rename
  #
  Wukong::Dfs.list_files(files_to_rename).each do |hdfs_file|
    filename_tokens = old_filename_pat.recognize(hdfs_file.path, { :segment => '\d+', :flavor => '\w+'}) or next
    filename_tokens.merge!(more_toks)
    if (filename_tokens[:timestamp].blank?) && (!filename_tokens[:date].blank?)
      timepart = filename_tokens[:time].blank? ? ('0'+filename_tokens[:segment]) : filename_tokens[:time]
      filename_tokens[:timestamp] = filename_tokens[:date] + (timepart || '000000')
    end
    new_filename = new_filename_pat.make(filename_tokens)
    rename_carefully hdfs_file, new_filename, opts[:go]
  end
end


  # '/user/flip/pkgd/user/flip/tw0227/bundled/bundled_bundled_*.bz2' =>
  # { :pat_str => ':any_id/bundled/bundled_bundled_:date.:ext',
  #   :toks    => { :ext => '.tsv.bz2' } },




# -rw-r--r--   3 flip supergroup 2055552674 2009-02-18 13:18 /user/flip/tw0218/bundled/bundled_fff_20090126-00000/bundled_fff_20090126-00000
# -rw-r--r--   3 flip supergroup 2328853732 2009-02-18 13:08 /user/flip/tw0218/bundled/bundled_fff_20090126-00001/bundled_fff_20090126-00001
# -rw-r--r--   3 flip supergroup  630259166 2009-02-18 13:55 /user/flip/tw0218/bundled/bundled_idok_0126_pt_0215-00053/bundled_idok_0126_pt_0215-00053
# -rw-r--r--   3 flip supergroup 1714844022 2009-02-17 12:17 /user/flip/tw0218/bundled/bundled_bundled_20090118/bundled-_20090118.tsv
# -rw-r--r--   3 flip supergroup 4053904382 2009-02-17 12:18 /user/flip/tw0218/bundled/bundled_bundled_20090119/bundled-_20090119.tsv
# -rw-r--r--   3 flip supergroup 3612882035 2009-02-17 12:36 /user/flip/tw0218/bundled/bundled_bundled_20090120/bundled-_20090120.tsv
# -rw-r--r--   3 flip supergroup 4309364084 2009-02-17 12:42 /user/flip/tw0218/bundled/bundled_bundled_20090121/bundled-_20090121.tsv
# -rw-r--r--   3 flip supergroup 4375598899 2009-02-17 12:49 /user/flip/tw0218/bundled/bundled_bundled_20090122/bundled-_20090122.tsv
# -rw-r--r--   3 flip supergroup 2414994564 2009-02-17 12:56 /user/flip/tw0218/bundled/bundled_bundled_20090123/bundled-_20090123.tsv
# -rw-r--r--   3 flip supergroup        612 2009-02-17 13:01 /user/flip/tw0218/bundled/bundled_bundled_20090125/bundled-_20090125.tsv
# -rw-r--r--   3 flip supergroup 1120007814 2009-02-17 13:03 /user/flip/tw0218/bundled/bundled_bundled_20090204/bundled-_20090204.tsv
# -rw-r--r--   3 flip supergroup  534874538 2009-02-17 13:06 /user/flip/tw0218/bundled/bundled_bundled_20090205/bundled-_20090205.tsv
# -rw-r--r--   3 flip supergroup  404436617 2009-02-17 13:07 /user/flip/tw0218/bundled/bundled_bundled_20090206/bundled-_20090206.tsv
# -rw-r--r--   3 flip supergroup  359037171 2009-02-17 13:08 /user/flip/tw0218/bundled/bundled_bundled_20090207/bundled-_20090207.tsv
# -rw-r--r--   3 flip supergroup  332668257 2009-02-17 13:08 /user/flip/tw0218/bundled/bundled_bundled_20090208/bundled-_20090208.tsv
# -rw-r--r--   3 flip supergroup  304904205 2009-02-17 13:09 /user/flip/tw0218/bundled/bundled_bundled_20090209/bundled-_20090209.tsv
# -rw-r--r--   3 flip supergroup  295217809 2009-02-17 13:09 /user/flip/tw0218/bundled/bundled_bundled_20090210/bundled-_20090210.tsv
# -rw-r--r--   3 flip supergroup  257376099 2009-02-17 13:10 /user/flip/tw0218/bundled/bundled_bundled_20090211/bundled-_20090211.tsv
# -rw-r--r--   3 flip supergroup  180147925 2009-02-17 13:10 /user/flip/tw0218/bundled/bundled_bundled_20090212/bundled-_20090212.tsv
# -rw-r--r--   3 flip supergroup  150611510 2009-02-17 13:11 /user/flip/tw0218/bundled/bundled_bundled_20090214/bundled-_20090214.tsv
# -rw-r--r--   3 flip supergroup  154181256 2009-02-17 13:11 /user/flip/tw0218/bundled/bundled_bundled_20090215/bundled-_20090215.tsv
# -rw-r--r--   3 flip supergroup   74288574 2009-02-17 13:12 /user/flip/tw0218/bundled/bundled_bundled_20090216/bundled-_20090216.tsv
# -rw-r--r--   3 flip supergroup    2006507 2009-02-17 13:12 /user/flip/tw0218/bundled/bundled_bundled_20090217/bundled-_20090217.tsv
# -rw-r--r--   3 flip supergroup  232422855 2009-02-17 13:11 /user/flip/tw0219/bundled/bundled_bundled_20090213/bundled-_20090213.tsv
# -rw-r--r--   3 flip supergroup  558290288 2009-02-27 16:52 /user/flip/tw0227/bundled/bundled_public_timeline_20090227/part-00004
# -rw-r--r--   3 flip supergroup 1130590440 2009-02-27 16:52 /user/flip/tw0227/bundled/bundled_public_timeline_20090227/part-00009
# -rw-r--r--   3 flip supergroup  523600649 2009-02-27 16:52 /user/flip/tw0227/bundled/bundled_public_timeline_20090227/part-00025
# -rw-r--r--   3 flip supergroup  565480025 2009-02-27 16:52 /user/flip/tw0227/bundled/bundled_public_timeline_20090227/part-00028
# -rw-r--r--   3 flip supergroup  566689087 2009-02-27 16:52 /user/flip/tw0227/bundled/bundled_public_timeline_20090227/part-00033
# -rw-r--r--   3 flip supergroup  545436522 2009-02-27 16:52 /user/flip/tw0227/bundled/bundled_public_timeline_20090227/part-00036
# -rw-r--r--   3 flip supergroup  563565767 2009-02-27 16:52 /user/flip/tw0227/bundled/bundled_public_timeline_20090227/part-00039
# -rw-r--r--   3 flip supergroup  544478849 2009-02-27 16:52 /user/flip/tw0227/bundled/bundled_public_timeline_20090227/part-00046
# -rw-r--r--   3 flip supergroup  566687292 2009-02-27 16:52 /user/flip/tw0227/bundled/bundled_public_timeline_20090227/part-00055

# -rw-r--r--   3 flip supergroup  561407978 2009-03-03 01:28 /user/flip/tw0227/bundled/bundled_public_timeline_20090227-0301/bundled_public_timeline_20090227-0301.tsv
# -rw-r--r--   3 flip supergroup  559109582 2009-03-03 01:22 /user/flip/tw0227/bundled/bundled_public_timeline_20090227-0302/bundled_public_timeline_20090227-0302.tsv
# -rw-r--r--   3 flip supergroup 1126272691 2009-03-01 04:53 /user/flip/tw0227/bundled/bundled_public_timeline_20090227-27_28/bundled_public_timeline_20090227-27_28.tsv
