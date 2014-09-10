require File.expand_path("../lib/wd/version", __FILE__)

task :build do
  system 'gem build wd.gemspec'
end

task :install => :build do
  system "gem install --no-rdoc --no-ri wd-#{Wd::VERSION}.gem"
end

task :default => :install
