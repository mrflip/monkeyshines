# Generated by jeweler
# DO NOT EDIT THIS FILE
# Instead, edit Jeweler::Tasks in Rakefile, and run `rake gemspec`
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{monkeyshines}
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Philip (flip) Kromer"]
  s.date = %q{2009-10-12}
  s.description = %q{A simple scraper for directed scrapes of APIs, feed or structured HTML. Plays nicely with wuclan and wukong.}
  s.email = %q{flip@infochimps.org}
  s.extra_rdoc_files = [
    "LICENSE.textile",
     "README.textile"
  ]
  s.files = [
    "examples/bulk_urls/scrape_bulk_urls.rb",
     "examples/rename_tree/rename_hdp_tree.rb",
     "examples/rename_tree/rename_ripd_tree.rb",
     "examples/rss_feeds/scrape_rss_feeds.rb",
     "examples/shorturls/README.textile",
     "examples/shorturls/bulkdump_shorturls.rb",
     "examples/shorturls/bulkload_shorturls.rb",
     "examples/shorturls/extract_urls.rb",
     "examples/shorturls/multiplex_shorturl_cache.rb",
     "examples/shorturls/old/multidump_and_fix_shorturls.rb",
     "examples/shorturls/old/shorturl_stats.rb",
     "examples/shorturls/scrape_shorturls.rb",
     "examples/shorturls/shorturl_request.rb",
     "examples/shorturls/shorturl_sequence.rb",
     "examples/shorturls/shorturl_start_tyrant.sh",
     "examples/shorturls/start_shorturl_cache.sh",
     "lib/monkeyshines.rb",
     "lib/monkeyshines/extensions.rb",
     "lib/monkeyshines/fetcher.rb",
     "lib/monkeyshines/fetcher/authed_http_fetcher.rb",
     "lib/monkeyshines/fetcher/base.rb",
     "lib/monkeyshines/fetcher/fake_fetcher.rb",
     "lib/monkeyshines/fetcher/http_fetcher.rb",
     "lib/monkeyshines/fetcher/http_head_fetcher.rb",
     "lib/monkeyshines/monitor.rb",
     "lib/monkeyshines/monitor/chunked_store.rb",
     "lib/monkeyshines/monitor/periodic_logger.rb",
     "lib/monkeyshines/monitor/periodic_monitor.rb",
     "lib/monkeyshines/options.rb",
     "lib/monkeyshines/recursive_runner.rb",
     "lib/monkeyshines/repository/base.rb",
     "lib/monkeyshines/repository/s3.rb",
     "lib/monkeyshines/request_stream.rb",
     "lib/monkeyshines/request_stream/base.rb",
     "lib/monkeyshines/request_stream/edamame_queue.rb",
     "lib/monkeyshines/request_stream/klass_request_stream.rb",
     "lib/monkeyshines/request_stream/simple_request_stream.rb",
     "lib/monkeyshines/runner.rb",
     "lib/monkeyshines/runner_core/options.rb",
     "lib/monkeyshines/runner_core/parsing_runner.rb",
     "lib/monkeyshines/scrape_job/old_paginated.rb",
     "lib/monkeyshines/scrape_job/recursive.rb",
     "lib/monkeyshines/scrape_request.rb",
     "lib/monkeyshines/scrape_request/paginated.rb",
     "lib/monkeyshines/scrape_request/raw_json_contents.rb",
     "lib/monkeyshines/scrape_request/signed_url.rb",
     "lib/monkeyshines/store.rb",
     "lib/monkeyshines/store/base.rb",
     "lib/monkeyshines/store/chunked_flat_file_store.rb",
     "lib/monkeyshines/store/conditional_store.rb",
     "lib/monkeyshines/store/factory.rb",
     "lib/monkeyshines/store/flat_file_store.rb",
     "lib/monkeyshines/store/key_store.rb",
     "lib/monkeyshines/store/null_store.rb",
     "lib/monkeyshines/store/read_thru_store.rb",
     "lib/monkeyshines/store/tokyo_tdb_key_store.rb",
     "lib/monkeyshines/store/tyrant_rdb_key_store.rb",
     "lib/monkeyshines/store/tyrant_tdb_key_store.rb",
     "lib/monkeyshines/utils/factory_module.rb",
     "lib/monkeyshines/utils/filename_pattern.rb",
     "lib/monkeyshines/utils/logger.rb",
     "lib/monkeyshines/utils/trollop-1.14/FAQ.txt",
     "lib/monkeyshines/utils/trollop-1.14/History.txt",
     "lib/monkeyshines/utils/trollop-1.14/Manifest.txt",
     "lib/monkeyshines/utils/trollop-1.14/README.txt",
     "lib/monkeyshines/utils/trollop-1.14/Rakefile",
     "lib/monkeyshines/utils/trollop-1.14/lib/trollop.rb",
     "lib/monkeyshines/utils/trollop-1.14/test/test_trollop.rb",
     "lib/monkeyshines/utils/trollop.rb",
     "lib/monkeyshines/utils/union_interval.rb",
     "lib/monkeyshines/utils/uri.rb",
     "lib/monkeyshines/utils/uuid.rb",
     "spec/monkeyshines_spec.rb",
     "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/mrflip/monkeyshines}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{A simple scraper for directed scrapes of APIs, feed or structured HTML.}
  s.test_files = [
    "spec/monkeyshines_spec.rb",
     "spec/spec_helper.rb",
     "examples/bulk_urls/scrape_bulk_urls.rb",
     "examples/rename_tree/rename_hdp_tree.rb",
     "examples/rename_tree/rename_ripd_tree.rb",
     "examples/rss_feeds/scrape_rss_feeds.rb",
     "examples/shorturls/bulkdump_shorturls.rb",
     "examples/shorturls/bulkload_shorturls.rb",
     "examples/shorturls/extract_urls.rb",
     "examples/shorturls/multiplex_shorturl_cache.rb",
     "examples/shorturls/old/multidump_and_fix_shorturls.rb",
     "examples/shorturls/old/shorturl_stats.rb",
     "examples/shorturls/scrape_shorturls.rb",
     "examples/shorturls/shorturl_request.rb",
     "examples/shorturls/shorturl_sequence.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<addressable>, [">= 0"])
      s.add_runtime_dependency(%q<uuid>, [">= 0"])
      s.add_runtime_dependency(%q<wukong>, [">= 0"])
    else
      s.add_dependency(%q<addressable>, [">= 0"])
      s.add_dependency(%q<uuid>, [">= 0"])
      s.add_dependency(%q<wukong>, [">= 0"])
    end
  else
    s.add_dependency(%q<addressable>, [">= 0"])
    s.add_dependency(%q<uuid>, [">= 0"])
    s.add_dependency(%q<wukong>, [">= 0"])
  end
end
