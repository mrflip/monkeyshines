# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{monkeyshines}
  s.version = "0.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Philip (flip) Kromer"]
  s.date = %q{2009-07-07}
  s.description = %q{A simple scraper for directed scrapes of APIs, feed or structured HTML. Plays nicely with wuclan and wukong.}
  s.email = %q{flip@infochimps.org}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.textile"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.textile",
     "Rakefile",
     "VERSION",
     "lib/monkeyshines.rb",
     "lib/monkeyshines/expanded_url.rb",
     "lib/monkeyshines/http_scraper.rb",
     "lib/monkeyshines/old_scrape_request.rb",
     "lib/monkeyshines/request_stream.rb",
     "lib/monkeyshines/scrape.rb",
     "lib/monkeyshines/scrape_request.rb",
     "lib/monkeyshines/scrape_store.rb",
     "lib/monkeyshines/scrape_store/flat_file_store.rb",
     "lib/monkeyshines/scrape_store/read_through_store.rb",
     "lib/monkeyshines/scraped_file.rb",
     "lib/monkeyshines/twitter_api.rb",
     "lib/monkeyshines/twitter_search_scraper.rb",
     "lib/wukong.rb",
     "scrape_from_file.rb",
     "spec/monkeyshines_spec.rb",
     "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/mrflip/monkeyshines}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{A simple scraper for directed scrapes of APIs, feed or structured HTML.}
  s.test_files = [
    "spec/monkeyshines_spec.rb",
     "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
