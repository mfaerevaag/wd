require 'wd/version'

module Wd extend self

  def hello
    ARGV.join ', '
  end

end
