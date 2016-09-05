require "harvest-ruby/version"
require 'gosu'

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
  TILE_SIZE = 64

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

  class Crop < Struct.new :x, :y, :img
    def initialize(*args)
      super
      @current_crop = img.first
    end

    def dead?
      rand > 0.95
    end

    def grow
      @current_crop = img.push(img.shift).first
    end

    def draw
      @current_crop.draw(x,y,0)
    end
  end

  class Cursor < Struct.new :img
    def initialize(*args)
      super
      @current = img.first
    end

    def animate
      @current = img.push(img.shift).first
    end

    def draw(x,y)
      @current.draw_rot(x,y,100,0)
    end
  end

  class HUD < Struct.new :x, :y, :img, :mode
    ICON_IN_TILESET = {
    # 0 => 'Blank'
      hoe: 1,
      can: 2,
      seed: 3,
      grab: 4,
      trash: 5
    #-1 => 'Active Overlay'
    }
    def draw
      ICON_IN_TILESET.each do |ico,idx|
        img[idx].draw(x,y+(idx*TILE_SIZE),98)
        img[-1].draw(x,y+(idx*TILE_SIZE),99,1,1,0xff_ffffff, :additive) if mode == ico
      end
    end
  end

  class Window < Gosu::Window
    include Helper

    MEDIA_PATH = File.expand_path('../media/', __dir__)

    def initialize
      super(800,600,false)

      @crops = []
      @cursor = Cursor.new(load_image('cursor.png', tile_size: 48))
      @hud = HUD.new(0,0,load_image('HUD.png'), :grab)
    end

    def load_image(file, tile_size: TILE_SIZE)
      @@images = {}
      @@images[file] ||= Gosu::Image.load_tiles(File.join(MEDIA_PATH, file), tile_size, tile_size, retro: true)
    end

    ACTION_LIST = {
      Gosu::Kb1 => [:set_mode, :hoe],
      Gosu::Kb2 => [:set_mode, :can],
      Gosu::Kb3 => [:set_mode, :seed],
      Gosu::Kb4 => [:set_mode, :grab],
      Gosu::Kb5 => [:set_mode, :trash],
      Gosu::MsLeft => :primary_action,
    }
    def button_up(id)
      self.send(*ACTION_LIST[id]) if ACTION_LIST.has_key?(id)
    end

    def update
      every 500.ms do
        @crops.delete_if do |crop|
          crop.grow
          crop.dead?
        end

        @cursor.animate
      end

      every 1.s do
        self.caption = "HarvestRuby v#{VERSION} | GO:#{@crops.size}"
      end
    end

    def draw
      Gosu.draw_rect(0,0,800,600,0xff_088040,0)
      @crops.each(&:draw)
      @cursor.draw(tgm(mouse_x), tgm(mouse_y))
      @hud.draw
    end

    def set_mode(mode)
      @hud.mode = mode
    end

    def primary_action
      puts "Do #{@hud.mode}"
      tile_x, tile_y = tgc(mouse_x), tgc(mouse_y)
      case @hud.mode
#       when :hoe
#       when :can
      when :seed
        @crops << Crop.new(tile_x,tile_y,load_image("Crops.png"))
#       when :grab
#       when :trash
      else
      end
    end
  end
end


HarvestRuby::Window.new.show if __FILE__ == $0
