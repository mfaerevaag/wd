require 'wd/helpers'
require 'wd/points'
require 'wd/error'

module Wd
  class Base
    class << self

      def warp(name)
        path = Wd::Points::get name: name

        Wd::print_and_exit path, 0
      end

      def add(name, force)
        Wd::Points::add! name, force: force

        Wd::print_and_exit "Added warp point '#{name}'"
      end

      def rm(names)
        Wd::Points::remove! names

        Wd::print_and_exit "Removed warp point(s): #{names.join(', ')}"
      end

      def ls
        points = Wd::Points::all

        if points.empty?
          puts "No warp points found"
        else
          puts "Warp points:"
          Wd::print_points points
        end

        exit 1
      end

      def show(name)
        if name.empty?
          points = Wd::Points::get path: ENV['PWD']
          Wd::print_points points

        else
          path = Wd::Points::get name: name

          Wd::print_point name, path
        end

        exit 1
      end

      def clean(force)
        orphans = Wd::Points::clean!

        unless orphans
          Wd::print_and_exit "No orphaned warp points"
        else
          Wd::print_and_exit "Removed warp point(s): #{orphans.join(', ')}"
        end
      end

    end
  end
end
