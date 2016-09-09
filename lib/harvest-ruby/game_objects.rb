module HarvestRuby
  class Crop < Struct.new :img, :water, :soil
    include Config

    attr_accessor :quality

    def initialize(*args)
      super
      @current_crop = img.first
      @state = cfg(:special_states).sown

      @quality = rand(cfg(:quality).initial)
    end

    def state
      inverse_idx = @state - img.size
      @state == cfg(:special_states).sown ? :sown : cfg(:special_states).key(inverse_idx) || :growing
    end

    # TODO: Adjust the corresponding config values
    # its quite hard to find the right balance of the numbers so that the game is neither too easy nor too hard.
    # maybe I should build a function which tries out different combinations for me to choose from.
    def grow
      if [:sown, :growing].include?(state)
        @state += 1

        # Adjust the quality of the crop
        @quality += self.water ? cfg(:quality).can : -cfg(:quality).can
        @quality += self.soil ? cfg(:quality).hoe : -cfg(:quality).hoe

        self.wither if @quality <= cfg(:quality).wither_threshold # && rand(100) >= cfg(:quality).wither_chance
      end
    end

    def harvest
      return 0 unless state == :ripe
      @state = img.size + cfg(:special_states).harvested

      # Earnings for the sold fruits.
      cfg(:reward).base + (@quality / 100.0 * rand(cfg(:reward).quality)).floor
    end

    def wither
      @state = img.size + cfg(:special_states).dead
    end

    def draw(x,y,z)
      img[cfg(:special_states).soil].draw(x,y,z) if self.soil
      img[cfg(:special_states).water].draw(x,y,z,1,1,0x30_ffffff, :additive) if self.water
      img[@state].draw(x,y,z)
    end
  end
end
