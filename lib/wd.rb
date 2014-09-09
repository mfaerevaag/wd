require 'wd/options'
require 'wd/version'

module Wd extend self

  attr_accessor :opts

  def run
    @opts = Options.new

    p "point: #{@opts.point}"
    exit
  end

end
