# -*- coding: utf-8 -*-
require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
    gem.name        = "monkeyshines"
    gem.authors     = ["Philip (flip) Kromer"]
    gem.email       = "flip@infochimps.org"
    gem.homepage    = "http://github.com/mrflip/monkeyshines"
    gem.summary     = %Q{A simple scraper for directed scrapes of APIs, feed or structured HTML.}
    gem.description = %Q{A simple scraper for directed scrapes of APIs, feed or structured HTML. Plays nicely with wuclan and wukong.}
    gem.executables = FileList['bin/*.rb'].pathmap('%f')
    gem.files       =  FileList["\w*", "**/*.textile", "examples/*", "{app,bin,docpages,examples,lib,spec,utils}/**/*"].reject{|file| file.to_s =~ %r{.*private.*} }
    gem.add_dependency 'addressable'
    gem.add_dependency 'uuid'
    gem.add_dependency 'wukong'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end
Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end
task :spec => :check_dependencies
task :default => :spec

begin
  require 'reek/rake_task'
  Reek::RakeTask.new do |t|
    t.fail_on_error = true
    t.verbose = false
    t.source_files = ['lib/**/*.rb', 'examples/**/*.rb', 'utils/**/*.rb']
  end
rescue LoadError
  task :reek do
    abort "Reek is not available. In order to run reek, you must: sudo gem install reek"
  end
end

begin
  require 'roodi'
  require 'roodi_task'
  RoodiTask.new do |t|
    t.verbose = false
  end
rescue LoadError
  task :roodi do
    abort "Roodi is not available. In order to run roodi, you must: sudo gem install roodi"
  end
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new do |yard|
  end
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  require 'rdoc'
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end
  rdoc.options += [
    '-SHN',
    '-f', 'darkfish',  # use darkfish rdoc styler
  ]
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "monkeyshines #{version}"
  #
  File.open(File.dirname(__FILE__)+'/.document').each{|line| rdoc.rdoc_files.include(line.chomp) }
end

begin
  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new(:features)
rescue LoadError
  task :features do
    abort "Cucumber is not available. In order to run features, you must: sudo gem install cucumber"
  end
end
