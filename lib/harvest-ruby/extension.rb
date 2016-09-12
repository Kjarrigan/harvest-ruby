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

class Hash
  def symbolize_keys
    (self.map do |key,value|
      v = value.kind_of?(Hash) ? value.symbolize_keys : value
      [key.to_sym, v]
    end).to_h
  end

  def method_missing(name, *args, &block)
    raise "undefined key: #{name}" unless self.has_key?(name)

    val = self[name]
    val = eval(val[1..-1]) if val =~ /^\$/
    val
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

    def to_grid_corner_coord(val, grid_size=CONFIG.window.tile_size)
      (val / grid_size).floor * grid_size
    end
    alias :tgc :to_grid_corner_coord

    def to_grid_center_coord(val, grid_size=CONFIG.window.tile_size)
      to_grid_corner_coord(val, grid_size) + (grid_size / 2)
    end
    alias :tgm :to_grid_center_coord


    # Note from gosu-docu: OpenGL lines are not reliable at all and may have a missing pixel at the start or end point. Relying on your machine's behavior can only end in tears. Recommended for debugging purposes only.
    def draw_line(x1, y1, c1, x2, y2, c2, z, w=1, mode=:default)
      if w == 1
        Gosu.draw_triangle(x1,y1,c1,x1+w,y1,c1,x2,y2,c2,z,mode)
      else
        Gosu.draw_quad(x1,y1,c1,x1+w,y1,c1,x2+w,y2,c2,x2,y2,c2,z,mode)
      end
    end

    def draw_arrow(x,y,z,c=0xff_000000,w=1)
      draw_line(x,y,c,x,y-50,c,z,w)
    end
  end

  module Config
    def cfg(*keys, b: nil)
      val = CONFIG.send(b || self.class.to_s.downcase.gsub('test', '').split('::').last.to_sym)
      keys.each do |k|
        val = val.send(k)
      end
      val = eval(val[1..-1]) if val =~ /^\$/
      val
    end
  end
end
