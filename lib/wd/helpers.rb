module Wd

  def self.print_and_exit(content, code = 1)
    puts content
    exit code
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
