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
  module Helper
    def every(milliseconds, execute_on_first_call=false)
      last_called_at = instance_variable_get("@timer_for#{caller.to_s.hash.abs}")

      if (last_called_at.nil? && execute_on_first_call) or (Gosu.milliseconds > last_called_at.to_i+milliseconds)
        yield
        instance_variable_set("@timer_for#{caller.to_s.hash.abs}", Gosu.milliseconds)
      end
    end
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

  class Window < Gosu::Window
    include Helper

    MEDIA_PATH = File.expand_path('../media/', __dir__)

    def initialize
      super(800,600,false)

      @crops = []
    end

    def load_image(file)
      @@images = {}
      @@images[file] ||= Gosu::Image.load_tiles(File.join(MEDIA_PATH, file), 64, 64, retro: true)
    end

    ACTION_LIST = {
      Gosu::KbSpace => :spawn_crop
    }
    def button_up(id)
      self.send(ACTION_LIST[id]) if ACTION_LIST.has_key?(id)
    end

    def update
      every 500.ms do
        @crops.delete_if do |crop|
          crop.grow
          crop.dead?
        end
      end

      every 1.s do
        self.caption = "HarvestRuby v#{VERSION} | GO:#{@crops.size}"
      end
    end

    def draw
      @crops.each(&:draw)
    end

    def spawn_crop
      x,y = rand(800-64), rand(600-64)
      @crops << Crop.new(x,y,load_image("Crops.png"))
    end
  end
end


HarvestRuby::Window.new.show if __FILE__ == $0
