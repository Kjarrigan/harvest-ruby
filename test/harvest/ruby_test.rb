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
    crop = HarvestRuby::Crop.new(Array.new(8))

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
end
