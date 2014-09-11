module Wd

  class Error < RuntimeError; end

  class PointError < Error
    attr_reader :point

    def initialize(msg, point)
      @point = point
      super msg
    end
  end

  class UnknownPoint < PointError
    def initialize(point)
      super "Unknown warp point '#{point}'", point
    end
  end

  class PointNotFound < PointError
    def initialize()
      super "No warp point found to #{Wd::pwd}", nil
    end
  end

  class OrphanedPoint < PointError
    def initialize(point)
      super "Orphaned warp point '#{point}' (non-existent directory)", point
    end
  end

  class PointAlreadyExists < PointError
    def initialize(point)
      super "Warp point '#{point}' already exists. Use --force to overwrite", point
    end
  end

end
