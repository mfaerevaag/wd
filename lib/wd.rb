require 'wd/engine'
require 'wd/points'
require 'wd/error'
require 'wd/version'

module Wd extend self

  attr_accessor :opts

  def run
    begin
      Wd::Engine::run

    rescue Wd::Error => e
      Wd::print "Error: #{e.message}", type: :critical

    end

    exit 1
  end

end
