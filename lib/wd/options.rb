require 'optparse'
require 'ostruct'

module Wd
  class Options

    def initialize
      @options = OpenStruct.new

      @options.config_file = '~/.warprc'

      opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: wd [options] [point]"

        opts.on("-c", "--config FILE", "Specify config file") do |file|
          @options.config_file = file
        end

        opts.on("-v", "--version", "Print version") do
          puts "wd v#{Wd::VERSION}"
          exit 1
        end

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit 1
        end
      end

      begin
        opt_parser.parse!
        @options.point = ARGV.shift

        if @options.point.nil?
          puts opt_parser
        end
      rescue OptionParser::MissingArgument => e
        puts e
        exit 1
      rescue OptionParser::InvalidOption => e
        puts e
        exit 1
      end
    end

    private

    def method_missing(meth, *args, &block)
      if @options.respond_to? meth
        @options.send meth
      else
        super
      end
    end

    def respond_to?(meth, include_private = false)
      if @options.respond_to? meth
        true
      else
        super
      end
    end

  end
end
