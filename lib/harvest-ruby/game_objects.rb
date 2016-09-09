module HarvestRuby
  class Crop < Struct.new :img, :water, :soil
    include Config

    def initialize(*args)
      super
      @current_crop = img.first
      @state = cfg(:special_states).sown
    end

    def state
      inverse_idx = @state - img.size
      @state == cfg(:special_states).sown ? :sown : cfg(:special_states).key(inverse_idx) || :growing
    end

    def grow
      @state += 1 if [:sown, :growing].include?(state)
    end

    def harvest
      return 0 unless state == :ripe
      @state = img.size + cfg(:special_states).harvested

      # Earnings for the sold fruits.
      cfg(:reward_base) + rand(cfg(:reward_random))
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
