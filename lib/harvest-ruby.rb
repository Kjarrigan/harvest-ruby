require "harvest-ruby/version"
require 'gosu'
require 'harvest-ruby/extension'
require 'harvest-ruby/ui'
require 'harvest-ruby/game_objects'

module HarvestRuby
  TILE_SIZE = 64
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
      @hud.coins = 50
      @hud.day = 1
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
      @hud.day += 1

      @crops.values.each do |crop|
        crop.grow

        crop.soil = false if rand > 0.7
        crop.water = false
      end
    end

    def manual_season_change
      @crops.values.each(&:wither)
    end

    def primary_action
      pos = Pos[tgc(mouse_x), tgc(mouse_y)]
      return if @hud.set_mode_if_clicked(pos)

      crop = @crops[pos]

      return false if (@hud.mode == :seed && crop) or (@hud.mode != :seed && !crop) or !@hud.pay

      case @hud.mode
      when :hoe
        crop.soil = true
      when :can
        crop.water = true
      when :seed
        @crops[pos] = Crop.new(load_image("Crops.png"))
      when :grab
        @hud.coins += crop.harvest
      when :trash
        @crops.delete(pos)
      end

      # necessary for the test
      return true
    end
  end
end
