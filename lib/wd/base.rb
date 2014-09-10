require 'pp'

require 'wd/helpers'

module Wd
  class Base
    class << self

      def warp(point)
        puts "WARPING TO #{point.to_s}"
        exit
      end

      def add(name, force)
        Wd::print_and_exit "ADDING #{name} (force: #{force.to_s})"
      end

      def rm(names)
        if names.kind_of? Array
          names = names.join(', ')
        end

        Wd::print_and_exit "REMOVING #{names}"
      end

      def ls
        Wd::print_and_exit "LISTING"
      end

      def show(name)
        Wd::print_and_exit "SHOWING #{name}"
      end

      def clean(force)
        Wd::print_and_exit "CLEANING (force: #{force.to_s})"
      end

    end
  end
end
