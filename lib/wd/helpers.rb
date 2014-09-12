module Wd

  def self.print(content, options = { type: :info })
    return if Wd::opts[:quiet]

    case options[:type]
    when :info then puts content if Wd::opts[:verbose]
    when :critical then puts content
    end
  end

  def self.print_and_exit(content, options = { code: 1, type: :info })
    self.print content, options
    exit(options[:code] || 1) # wtf
  end

  def self.print_point(name, path)
    path.gsub! ENV['HOME'], '~'
    printf "\t%s > %s\n", name, path
  end

  def self.print_points(points)
    longest_key = points.keys.max { |a, b| a.length <=> b.length }

    points.each do |name, path|
      path.gsub! ENV['HOME'], '~'
      printf "\t%-#{longest_key.length}s > %s\n", name, path
    end
  end

  def self.pwd
    ENV['PWD'].gsub ENV['HOME'], '~'
  end

end
