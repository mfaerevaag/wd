require 'wd/engine'
require 'wd/points'
require 'wd/version'

module Wd extend self

  def run
    Wd::Engine::run

    exit 1
  end

end
