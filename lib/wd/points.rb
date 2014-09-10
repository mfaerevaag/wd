require 'fileutils'
require 'csv'

module Wd
  class Points

    def initialize(config_file)
      @config_file = config_file

      @points = read_points
    end

    def all
      @points
    end

    def has?(key)
      @points.has_key? key
    end

    def add!(key, value, options={ force: false })
      key = key.to_sym

      if !@points.has? key or options[:force]
        @points[key] = value
        true
      else
        false
      end
    end

    def remove!(key)
      if @points.delete key
        true
      else
        false
      end
    end

    def persist!
      # lazy create config file
      unless File.file?(config_file)
        FileUtils.touch(config_file)
      end

      CSV.open(@config_file, 'wb') do |csv|
        @points.each do |key, value|
          csv << [key.to_s, value]
        end
      end
    end

    private

    def read_points
      points = {}
      return points  unless File.file?(@config_file)

      CSV.foreach(@config_file) do |row|
        key = row.shift.to_sym
        value = row.shift

        points[key] = value
      end

      points
    end

  end
end
