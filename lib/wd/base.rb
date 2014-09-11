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

        if names.is_a? Array
          Wd::print_and_exit "Removed warp points #{names.join(', ')}"
        else
          Wd::print_and_exit "Removed warp point #{names}"
        end
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
        Wd::print_and_exit "TODO: CLEAN (force: #{force})"
      end

    end
  end
end
