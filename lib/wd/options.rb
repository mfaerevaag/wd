require 'slop'

require 'wd/version'
require 'wd/helpers'

module Wd
  class Options

    DEFAULTS = {
      config: "#{ENV['HOME']}/.wdrc"
    }

    def initialize
      @opts = Slop.new(strict: true) do
        banner 'Usage: wd [options] <command> [<point>]'

        on :c, :config=,
        "Specify config file",
        default: DEFAULTS[:config]

        on :q, :quiet,
        "Silence all output",
        default: false

        on '-v', '--version', 'Print version' do
          Wd::print_and_exit "wd v#{Wd::VERSION}"
        end

        on '-h', '--help', 'Print this message' do
          Wd::print_and_exit help
        end

        add_callback(:empty) do
          Wd::print_and_exit help
        end

        command :add do
          description 'Add warp point'
          banner 'Usage: wd [--force] add <point>'

          on :f, :force,
          'Force overwriting existing warp point',
          default: false

          run do |opts, args|
            unless args.length == 1
              raise Slop::InvalidArgumentError.new 'add expects one and only one argument'
            end
          end
        end

        command :rm do
          description 'Remove warp point(s)'
          banner 'Usage: wd rm <point> [<point>...]'

          run do |opts, args|
            unless args.length > 0
              raise Slop::InvalidArgumentError.new 'rm expects one or more arguments'
            end
          end
        end

        command :ls do
          description 'List warp points'
          banner 'Usage: wd ls'

          run do |opts, args|
            if args.length > 0
              raise Slop::InvalidArgumentError.new 'ls takes no arguments'
            end
          end
        end

        command :show do
          description 'Show warp points to current directory or path to given warp point'
          banner 'Usage: wd show [<point>]'

          run do |opts, args|
            if args.length > 1
              raise Slop::InvalidArgumentError.new 'show takes only one (optional) argument'
            end
          end
        end

        command :clean do
          description 'Remove orphaned warp points (to non-existent directories)'
          banner 'Usage: wd [--force] clean'

          on :f, :force,
          'Do not prompt with confirmation',
          default: false

          run do |opts, args|
            if args.length > 0
              raise Slop::InvalidArgumentError.new 'clean takes no arguments'
            end
          end
        end
      end

      begin
        @opts.parse!
      rescue Slop::Error => e
        Wd::print_and_exit "Error: #{e}"
      end
    end

    def all
      @opts.to_hash(true)
    end

    # def set_command(cmd)
    #   unless @command.nil?
    #     print_and_exit "Error: multiple commands given (got #{@command.to_s} and #{cmd.to_s})"
    #   else
    #     @command = cmd
    #   end
    # end

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
