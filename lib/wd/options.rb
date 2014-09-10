require 'slop'

require 'wd/version'
require 'wd/helpers'

module Wd
  class Options

    CONFIG_FILE_DEFAULT = "#{ENV['HOME']}/.wdrc"

    def initialize
      @opts = Slop.new(strict: true) do
        banner 'Usage: wd [options] <command> [<point>]'

        on :c, :config=,
        "Specify config file",
        default: CONFIG_FILE_DEFAULT

        on :q, :quiet,
        "Silence all output",
        default: false

        on '-v', '--version', 'Print version' do
          Wd::print_and_exit "wd v#{Wd::VERSION}"
        end

        on '-h', '--help', 'Print this message' do
          Wd::print_and_exit self.help
        end

        command :add do
          description 'Add warp point'
          banner 'Usage: wd [--force] add <point>'

          on :f, :force,
          'Force overwriting existing warp point',
          default: false

          run do |opts, args|
            self
          end
        end

        command :rm do
          description 'Remove warp point(s)'
          banner 'Usage: wd rm <point> [<point>...]'

          run do |opts, args|
            puts "Ran 'rm' with options #{opts.to_hash} and args: #{args.inspect}"
          end
        end

        command :ls do
          description 'List warp points'
          banner 'Usage: wd ls'

          run do |opts, args|
            puts "Ran 'ls' with options #{opts.to_hash} and args: #{args.inspect}"
          end
        end

        command :show do
          description 'Show warp points to current directory or path to given warp point'
          banner 'Usage: wd show [<point>]'

          run do |opts, args|
            puts "Ran 'show' with options #{opts.to_hash} and args: #{args.inspect}"
          end
        end

        command :clean do
          description 'Remove orphaned warp points (to non-existent directories)'
          banner 'Usage: wd [--force] clean'

          on :f, :force,
          'Do not prompt with confirmation',
          default: false

          run do |opts, args|
            puts "Ran 'clean' with options #{opts.to_hash} and args: #{args.inspect}"
          end
        end
      end

      begin
        @opts.parse!
      rescue Slop::Error => e
        Wd::print_and_exit e
      end

      p @opts.to_hash(true)
    end

    private

    def method_missing(meth, *args, &block)
      unless @opts.to_hash(true)[meth].nil?
        @opts.to_hash(true)[meth]
      else
        super
      end
    end

    def respond_to?(meth, include_private = false)
      unless @opts.to_hash(true)[meth].nil?
        true
      else
        super
      end
    end

  end
end
