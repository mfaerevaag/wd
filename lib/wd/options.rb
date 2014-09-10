require 'slop'

require 'wd/version'

module Wd
  class Options

    CONFIG_FILE_DEFAULT = "#{ENV['HOME']}/.wdrc"

    def initialize
      @options = Slop.parse(help: true) do
        banner 'Usage: wd [options] <command> [<point>]'

        on :c, :config=,
        "Specify config file",
        default: CONFIG_FILE_DEFAULT

        on :q, :quiet,
        "Silence all output",
        default: false

        on '-v', '--version', 'Print version' do
          puts "wd v#{Wd::VERSION}"
          exit 1
        end

        command :add do
          description 'Add warp point'
          banner 'Usage: wd [--force] add <point>'

          on :f, :force,
          'Force overwriting existing warp point',
          default: false

          run do |opts, args|
            puts "Ran 'add' with options #{opts.to_hash} and args: #{args.inspect}"
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

      p @options.to_hash(true)
    end

    private

    def method_missing(meth, *args, &block)
      unless @options.to_hash(true)[meth].nil?
        @options.to_hash(true)[meth]
      else
        super
      end
    end

    def respond_to?(meth, include_private = false)
      unless @options.to_hash(true)[meth].nil?
        true
      else
        super
      end
    end

  end
end
