module HarvestRuby
  class Cursor < Struct.new :img
    def initialize(*args)
      super
      @current = img.first
    end

    def animate
      @current = img.push(img.shift).first
    end

    def draw(x,y)
      @current.draw_rot(x,y,100,0)
    end
  end

  class HUD < Struct.new :x, :y, :width, :img, :mode, :coins, :day
    include Helper

    ICON_IN_TILESET = {
      # 0 => 'Blank'
      hoe: 1,
      can: 2,
      seed: 3,
      grab: 4,
      trash: 5
    #-1 => 'Active Overlay'
    }
    SMALL_FONT_SIZE = 20
    BIG_FONT_SIZE = 40
    def initialize(*args)
      super
      @small = Gosu::Font.new(SMALL_FONT_SIZE)
      @big = Gosu::Font.new(BIG_FONT_SIZE)
      @button_pos = {}
      ICON_IN_TILESET.each do |action,idx|
        @button_pos[Pos.new(tgc(x+(idx*TILE_SIZE)), tgc(y))] = action
      end
    end

    def set_mode_if_clicked(pos)
      hit = @button_pos[pos]
      self.mode = hit unless hit.nil?
    end

    ACTION_COST = {
      hoe:   5,
      can:   2,
      seed: 10,
      grab:  0,
      trash: 2,
    }
    def pay
      cost = ACTION_COST[self.mode]
      self.coins >= cost  ? (self.coins -= cost) : false
    end

    def draw
      # Panel Background
      (width / TILE_SIZE.to_f).ceil.times do |i|
        img[0].draw(x+(i*TILE_SIZE),y,97)
      end

      # Panel Actions
      ICON_IN_TILESET.each do |ico,idx|
        pos = Pos.new(x+(idx*TILE_SIZE),y)

        img[idx].draw(pos.x,pos.y,98)
        if mode == ico
          img[-1].draw(pos.x,pos.y,99,1,1,0xf0_ffffff, :additive)
          @small.draw(ACTION_COST[ico].to_s+' €',pos.x+15,pos.y+35,99,1,1,ACTION_COST[ico] > 0 ? 0xff_ff0000 : 0xff_088130)
        else
          @small.draw(idx,pos.x+40,pos.y+35,99,1,1,0xff_ffffff)
        end
      end

      # Currency
      @big.draw("€ " + self.coins.to_s, x+20+(ICON_IN_TILESET.size+1)*TILE_SIZE, y+TILE_SIZE-BIG_FONT_SIZE, 98, 1, 1, 0xff_000000)

      # Day
      @big.draw("Day " + day.to_s, x+20+(ICON_IN_TILESET.size+4)*TILE_SIZE, y+TILE_SIZE-BIG_FONT_SIZE, 98, 1, 1, 0xff_000000)
    end
  end
end
