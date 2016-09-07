class Integer
  def ms
    self
  end

  def s
    self * 1000
  end

  def min
    self * 1000 * 60
  end
end

module HarvestRuby
  class Pos < Struct.new :x, :y
    def self.[](x,y)
      new(x,y)
    end
  end

  module Helper
    def every(milliseconds, execute_on_first_call=false)
      last_called_at = instance_variable_get("@timer_for#{caller.to_s.hash.abs}")

      if (last_called_at.nil? && execute_on_first_call) or (Gosu.milliseconds > last_called_at.to_i+milliseconds)
        yield
        instance_variable_set("@timer_for#{caller.to_s.hash.abs}", Gosu.milliseconds)
      end
    end

    def to_grid_corner_coord(val, grid_size=TILE_SIZE)
      (val / grid_size).floor * grid_size
    end
    alias :tgc :to_grid_corner_coord

    def to_grid_center_coord(val, grid_size=TILE_SIZE)
      to_grid_corner_coord(val, grid_size) + (grid_size / 2)
    end
    alias :tgm :to_grid_center_coord
  end
end
