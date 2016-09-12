require "harvest-ruby/version"
require 'gosu'
require 'harvest-ruby/extension'
require 'harvest-ruby/ui'
require 'harvest-ruby/game_objects'
require 'yaml'

module HarvestRuby
  CONFIG = YAML.load_file(File.expand_path('../config.yml', __dir__)).symbolize_keys

  class Window < Gosu::Window
    include Helper
    include Config

    MEDIA_PATH = File.expand_path('../media/', __dir__)
    attr_reader :game_mode

    def initialize
      super(cfg(:width),cfg(:height),false)

      @cursor = Cursor.new(load_image('cursor.png', tile_size: cfg(:cursor_size)))
      @hud = HUD.new(0,0,cfg(:width),load_image('HUD.png'), cfg(:default_mode))
      @font_title = Gosu::Font.new(50, name: File.join(MEDIA_PATH, 'orange_juice_2.0.ttf'))
      @font_main = Gosu::Font.new(30, name: File.join(MEDIA_PATH, 'orange_juice_2.0.ttf'))
      @font_note = Gosu::Font.new(25, name: File.join(MEDIA_PATH, 'orange_juice_2.0.ttf'))

      reset_game
      @game_mode = :menu
    end

    def reset_game
      @crops = {}
      @hud.coins = cfg(:start_coins)
      @hud.day = 1
      @game_mode = :running
    end

    def load_image(file, tile_size: cfg(:tile_size))
      @@images = {}
      @@images[file] ||= Gosu::Image.load_tiles(File.join(MEDIA_PATH, file), tile_size, tile_size, retro: true)
    end

    ACTION_LIST = {
      Gosu::KbSpace => :manual_game_tick,
      Gosu::KbF1 => [:set_game_mode, :help],
      Gosu::KbEscape => [:set_game_mode, :menu],
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

    HELP = {
      'Remove (5) the plant': {arrow: 5, x_offset: 30},
      'Grab (4) & sell the fruits': {arrow: 4, x_offset: 30},
      'Plant a seed (3) on an empty field for a new crop': {arrow: 3, x_offset: 30},
      'Using the can (2) on a crop increases its quality': {arrow: 2, x_offset: 30},
      'Using the hoe (1) on a crop increases its quality slightly': {arrow: 1, x_offset: 30},
      '- Beware - everything except grabbing cost some': {},
      'coins (see the selected field for the amount)': {x_offset: 20},
      '- The game is turn-based - press <SPACE>': {},
      'to end the day.': {x_offset: 20},
      "- The game is over after 90 days": {}
    }
    def draw
      Gosu.draw_rect(0,0,cfg(:width),cfg(:height),cfg(:bg_color),0)
      @crops.each do |pos,crop|
        crop.draw(pos.x, pos.y, 5)
      end
      @hud.draw

      case @game_mode
      when :menu
        Gosu.draw_rect(0,0,cfg(:width),cfg(:height),cfg(:pause_color),500)
        @font_title.draw_rel("HarvestRuby v#{VERSION}",cfg(:width)/2,cfg(:height)/2,501, 0.5, 0.5, 1.0, 1.0, 0xff_000000)
        @font_main.draw_rel("Press  <SPACE> to start/continue",cfg(:width)/2,cfg(:height)/2+50,501, 0.5, 0.5, 1.0, 1.0, 0xff_000000)
        @font_main.draw_rel("Press  <F1> for help",cfg(:width)/2,cfg(:height)/2+80,501, 0.5, 0.5, 1.0, 1.0, 0xff_000000)
        @font_main.draw_rel("Press  <ESC> to quit",cfg(:width)/2,cfg(:height)/2+110,501, 0.5, 0.5, 1.0, 1.0, 0xff_000000)
      when :help
        Gosu.draw_rect(0,0,cfg(:width),cfg(:height),cfg(:pause_color),500)
        dy = 1.5
        HELP.each.with_index(1) do |(note,options), idx|
          x = cfg(:tile_size)
          dx = options[:x_offset] || 0
          if options.has_key?(:arrow)
            x *= options[:arrow]
            y = cfg(:tile_size)*dy-10
            c = 0xff_000000
            draw_line(x+dx,y,c,x+dx,cfg(:tile_size),c,501,2)
          end
          @font_note.draw(note, x+dx, cfg(:tile_size)*dy, 501, 1, 1, 0xff_000000)
          dy += 0.5
        end
      when :running
        @cursor.draw(tgm(mouse_x), tgm(mouse_y))
      when :finished
        Gosu.draw_rect(0,0,cfg(:width),cfg(:height),cfg(:pause_color),500)

        txt = game_lost? ? 'GameOver' : 'Victory'
        @font_title.draw_rel(txt,cfg(:width)/2,cfg(:height)/2,501, 0.5, 0.7, 1.0, 1.0, 0xff_000000)

        @font_main.draw_rel("Press  <SPACE> to start a new game",cfg(:width)/2,cfg(:height)/2+50,501, 0.5, 0.5, 1.0, 1.0, 0xff_000000)
        @font_main.draw_rel("Press  <ESC> to quit",cfg(:width)/2,cfg(:height)/2+110,501, 0.5, 0.5, 1.0, 1.0, 0xff_000000)
      end
    end

    def set_mode(mode)
      @hud.mode = mode if @game_mode == :running
    end

    def manual_game_tick
      case @game_mode
      when :running
        @crops.values.each do |crop|
          crop.grow

          crop.soil = false if rand > 0.7
          crop.water = false
        end

        @game_mode = :finished if game_lost? or @hud.day == 90
        @hud.day += 1
      when :finished
        reset_game
      else
        @game_mode = :running
      end
    end

    def game_lost?
      no_harvestable_crops_remaining = @crops.map do |_,crop|
        [:harvested, :dead].include?(crop.state)
      end
      (@crops.empty? or no_harvestable_crops_remaining.inject(:&)) && @hud.coins < 20
    end

    def primary_action
      return false unless @game_mode == :running

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

    def set_game_mode(mode)
      if @game_mode == :menu && mode == :menu
        close
      end

      @game_mode = @game_mode == mode ? :running : mode
    end
  end
end
