# -*- coding: utf-8 -*-

require File.expand_path("../lib/wd/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = 'wd'
  s.version     = Wd::VERSION
  s.date        = '2014-09-09'

  s.summary     = 'warp directory'
  s.description = 'wd lets you jump to custom directories in zsh, without using cd'

  s.authors     = [ 'Markus Færevaag', 'Simon Altschuler' ]
  s.email       = 'mafaer@gmail.com'
  s.homepage    = 'https://github.com/mfaerevaag/wd'
  s.license     = 'MIT'

  s.files       = Dir.glob "{lib}/**/*.rb"
  s.executables << '_wd'

  s.add_dependency 'slop', '~> 3.6', '>= 3.6.0'
end
