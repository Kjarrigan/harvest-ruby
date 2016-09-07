module HarvestRuby
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
      return 0 unless state == :ripe
      @state = img.size + SPECIAL_STATES[:harvested]

      # Earnings for the sold fruits.
      10 + rand(11)
    end

    def wither
      @state = img.size + SPECIAL_STATES[:dead]
    end

    def draw(x,y,z)
      img[@state].draw(x,y,z)
    end
  end
end
