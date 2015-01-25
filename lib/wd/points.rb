require 'fileutils'
require 'csv'

require 'wd/error'

module Wd
  class Points
    class << self

      def all
        points
      end

      def has?(name)
        points.has_key? name
      end

      def get(options = { name: nil, path: nil })
        if !options[:name].nil?
          name = options[:name]

          unless self.has? name
            raise Wd::UnknownPoint.new name
          end

          path = points[name]
          unless File.directory? path
            raise Wd::OrphanedPoint.new name
          end
          path

        elsif !options[:path].nil?
          path = options[:path]

          unless points.has_value? path
            raise Wd::PointNotFound.new
          end

          points.select { |k,v| v == path }
        end
      end

      def add!(name, options={ force: false })
        if Wd::Points::has?(name) && !options[:force]
          raise Wd::PointAlreadyExists.new name
        end

        points[name] = ENV['PWD']

        self.persist!
      end

      def remove!(names)
        if names.is_a? Symbol
          names = [ names ]
        end

        # check if names exists
        names.each do |name|
          unless self.has? name
            raise Wd::UnknownPoint.new name
          end
        end

        # remove
        names.each do |name|
          points.delete name
        end

        self.persist!
      end

      def clean!
        orphans = points.select do |name, path|
          !File.directory? path
        end

        unless orphans.empty?
          self.remove! orphans.keys
          orphans.keys
        else
          false
        end
      end

      def persist!
        config_file = Wd::opts[:config]

        # lazy create config file
        unless File.file?(config_file)
          FileUtils.touch(config_file)
        end

        CSV.open(config_file, 'wb', col_sep: ':') do |csv|
          points.each do |key, value|
            csv << [key.to_s, value]
          end
        end
      end

      private

      def points
        @points ||= read_points
      end

      def read_points
        points = {}
        config = Wd::opts[:config]

        return points unless File.file?(config)

        CSV.foreach(config, col_sep: ':') do |row|
          unless row.empty?
            key = row.shift.to_sym
            value = row.shift

            points[key] = value
          end
        end

        points
      end

    end
  end
end
