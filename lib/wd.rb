require 'wd/options'
require 'wd/points'
require 'wd/version'

require 'pp'

module Wd extend self

  attr_accessor :opts, :points

  def run
    @opts = Options.new
    @points = Points.new(@opts.config)

    puts "opts:"
    pp @opts.all

    puts "args:"
    pp ARGV

    puts "points:"
    pp @points.all

    exit 1
  end

end
