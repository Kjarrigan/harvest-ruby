require 'test_helper'

class Test < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::HarvestRuby::VERSION
  end

  def test_crop_state_calculation
    expectation = {
      0 => :sown,
      1 => :growing,
      2 => :growing,
      3 => :growing,
      4 => :growing,
      5 => :ripe
    }
    crop = HarvestRuby::Crop.new(Array.new(10))

    expectation.each do |idx,expected_state|
      assert_equal crop.state, expected_state, "Iteration ##{idx+1}"
      crop.grow
    end

    # no matter how often you call grow, if it's ripe nothing should happen.
    # the remaining two states are only triggered by event
    10.times do crop.grow end
    assert_equal crop.state, :ripe

    crop.harvest
    assert_equal crop.state, :harvested

    crop.wither
    assert_equal crop.state, :dead
  end

  def test_primary_action
    window = TestWindow.new
    dummy_pos = HarvestRuby::Pos[2*HarvestRuby::CONFIG.window.tile_size,2*HarvestRuby::CONFIG.window.tile_size]
    window.mouse_x = dummy_pos.x
    window.mouse_y = dummy_pos.y

    # There are two things to consider if an action has to be done:
    # is there are crop (or in change of seed-mode inverse) and do i have enough coins
    [false, true].each do |crop_available|
      {false => 0, true => 100}.each do |enough_money_for_action,coins|
        HarvestRuby::CONFIG.hud.action_cost.each do |action, cost|

          window.crops.delete(dummy_pos)
          if crop_available
            window.crops[dummy_pos] = HarvestRuby::Crop.new(Array.new(10))
          end

          window.hud.coins = coins
          window.set_mode(action)

          expectation = if action == :seed
            enough_money_for_action && !crop_available
          elsif action == :grab
            crop_available
          else
            enough_money_for_action && crop_available
          end
          msg = "action: #{action} + crop: #{crop_available} + money: #{enough_money_for_action} -> action: #{expectation}"

          # check if the action is performed ...
          assert_equal expectation, window.primary_action, msg

          # ... and the coins are removed if it is
          if action == :grab && expectation
            assert window.hud.coins >= coins
          else
            assert_equal expectation ? coins - cost : coins, window.hud.coins, msg
          end
        end
      end
    end
  end
end
