$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'harvest-ruby'

class TestWindow < HarvestRuby::Window
  attr_accessor :mouse_x, :mouse_y
  attr_reader :crops
  attr_reader :hud
  attr_writer :game_mode
end

require 'minitest/autorun'
