module HarvestRuby
  class Crop < Struct.new :img, :water, :soil
    SPECIAL_STATES = {
      sown: 0,
      ripe: -5,
      harvested: -4,
      dead: -3,
      water: -2,
      soil: -1
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
      return 0 unless state == :ripe
      @state = img.size + SPECIAL_STATES[:harvested]

      # Earnings for the sold fruits.
      10 + rand(11)
    end

    def wither
      @state = img.size + SPECIAL_STATES[:dead]
    end

    def draw(x,y,z)
      img[SPECIAL_STATES[:soil]].draw(x,y,z) if self.soil
      img[SPECIAL_STATES[:water]].draw(x,y,z,1,1,0x30_ffffff, :additive) if self.water
      img[@state].draw(x,y,z)
    end
  end
end
