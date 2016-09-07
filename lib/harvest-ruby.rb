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

  class Crop < Struct.new :img
    SPECIAL_STATES = {
      sown: 0,
      ripe: -3,
      harvested: -2,
      dead: -1
    }
    def initialize(*args)
      super
      @current_crop = img.first
      @state = 0
    end

    def state
      inverse_idx = @state - img.size
      @state == 0 ? :sown : SPECIAL_STATES.key(inverse_idx) || :growing
    end

    def grow
      @state += 1 if [:sown, :growing].include?(state)
    end

    def harvest
      return false unless state == :ripe
      @state = img.size + SPECIAL_STATES[:harvested]
    end

    def wither
      @state = img.size + SPECIAL_STATES[:dead]
    end

    def draw(x,y,z)
      img[@state].draw(x,y,z)
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

  class HUD < Struct.new :x, :y, :width, :img, :mode, :coins
    ICON_IN_TILESET = {
    # 0 => 'Blank'
      hoe: 1,
      can: 2,
      seed: 3,
      grab: 4,
      trash: 5
    #-1 => 'Active Overlay'
    }
      FONT_HEIGHT = 40
    def initialize(*args)
      super
      @font = Gosu::Font.new(FONT_HEIGHT)
    end

    def draw
      # Panel Background
      (width / TILE_SIZE.to_f).ceil.times do |i|
        img[0].draw(x+(i*TILE_SIZE),y,97)
      end

      # Panel Actions
      ICON_IN_TILESET.each do |ico,idx|
        img[idx].draw(x+(idx*TILE_SIZE),y,98)
        img[-1].draw(x+(idx*TILE_SIZE),y,99,1,1,0xff_ffffff, :additive) if mode == ico
      end

      # Currency
      @font.draw("€ " + coins.to_s, x+20+(ICON_IN_TILESET.size+1)*TILE_SIZE, y+TILE_SIZE-FONT_HEIGHT, 98)
    end
  end

  class Window < Gosu::Window
    include Helper

    MEDIA_PATH = File.expand_path('../media/', __dir__)
    WIDTH = 768
    HEIGHT = 512
    def initialize
      super(WIDTH,HEIGHT,false)

      @crops = {}
      @cursor = Cursor.new(load_image('cursor.png', tile_size: 48))
      @hud = HUD.new(0,0,WIDTH,load_image('HUD.png'), :grab)
      @hud.coins = 100
    end

    def load_image(file, tile_size: TILE_SIZE)
      @@images = {}
      @@images[file] ||= Gosu::Image.load_tiles(File.join(MEDIA_PATH, file), tile_size, tile_size, retro: true)
    end

    ACTION_LIST = {
      Gosu::KbSpace => :manual_game_tick,
      Gosu::KbReturn => :manual_season_change,
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
        @cursor.animate
      end

      every 1.s do
        self.caption = "HarvestRuby v#{VERSION} | GO:#{@crops.size}"
      end
    end

    def draw
      Gosu.draw_rect(0,0,WIDTH,HEIGHT,0xff_4d4331,0)
      @crops.each do |pos,crop|
        crop.draw(pos.x, pos.y, 5)
      end
      @cursor.draw(tgm(mouse_x), tgm(mouse_y))
      @hud.draw
    end

    def set_mode(mode)
      @hud.mode = mode
    end

    def manual_game_tick
      @crops.values.each(&:grow)
    end

    def manual_season_change
      @crops.values.each(&:wither)
    end

    def primary_action
      puts "Do #{@hud.mode}"
      pos = Pos[tgc(mouse_x), tgc(mouse_y)]
      crop = @crops[pos]
      case @hud.mode
#       when :hoe
#       when :can
      when :seed
        return false if crop
        @crops[pos] = Crop.new(load_image("Crops.png"))
      when :grab
        return false unless crop
        crop.harvest
      when :trash
        return false unless crop
        @crops.delete(pos)
      else
      end
    end
  end
end


HarvestRuby::Window.new.show if __FILE__ == $0
