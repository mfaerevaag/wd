require 'slop'

require 'wd/version'
require 'wd/helpers'
require 'wd/base'

module Wd
  class Engine
    class << self

      DEFAULTS = {
        config: "#{ENV['HOME']}/.wdrc"
      }

      def run
        Wd::opts = Slop.new(strict: true) do
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

          # add_callback(:empty) do
          #   Wd::print_and_exit help
          # end

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

              Wd::Base::add args.shift.to_sym, opts[:force]
            end
          end

          command :rm do
            description 'Remove warp point(s)'
            banner 'Usage: wd rm <point> [<point>...]'

            run do |opts, args|
              unless args.length > 0
                raise Slop::InvalidArgumentError.new 'rm expects one or more arguments'
              end

              Wd::Base::rm args.map { |x| x.to_sym }
            end
          end

          command :ls do
            description 'List warp points'
            banner 'Usage: wd ls'

            run do |opts, args|
              if args.length > 0
                raise Slop::InvalidArgumentError.new 'ls takes no arguments'
              end

              Wd::Base::ls
            end
          end

          command :show do
            description 'Show warp points to current directory or path to given warp point'
            banner 'Usage: wd show [<point>]'

            run do |opts, args|
              if args.length > 1
                raise Slop::InvalidArgumentError.new 'show takes only one (optional) argument'
              end

              Wd::Base::show (args.shift || '').to_sym
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

              Wd::Base::clean opts[:force]
            end
          end
        end

        begin
          Wd::opts.parse!

          if ARGV.empty?
            Wd::print_and_exit Wd::opts.help
          elsif ARGV.length > 1
            raise Slop::InvalidArgumentError.new 'Invalid number of arguments'
          else
            Wd::Base::warp ARGV.shift.to_sym
          end

        rescue Slop::Error => e
          Wd::print_and_exit "Error: #{e}"

        end
      end

    end
  end
end
