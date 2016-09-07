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

  class HUD < Struct.new :x, :y, :width, :img, :mode, :coins
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
    FONT_HEIGHT = 40
    def initialize(*args)
      super
      @font = Gosu::Font.new(FONT_HEIGHT)
      @button_pos = {}
      ICON_IN_TILESET.each do |action,idx|
        @button_pos[Pos.new(tgc(x+(idx*TILE_SIZE)), tgc(y))] = action
      end
    end

    def set_mode_if_clicked(pos)
      hit = @button_pos[pos]
      self.mode = hit unless hit.nil?
    end

    def draw
      # Panel Background
      (width / TILE_SIZE.to_f).ceil.times do |i|
        img[0].draw(x+(i*TILE_SIZE),y,97)
      end

      # Panel Actions
      ICON_IN_TILESET.each do |ico,idx|
        img[idx].draw(x+(idx*TILE_SIZE),y,98)
        img[-1].draw(x+(idx*TILE_SIZE),y,99,1,1,0xff_ffffff, :additive) if mode == ico
      end

      # Currency
      @font.draw("€ " + coins.to_s, x+20+(ICON_IN_TILESET.size+1)*TILE_SIZE, y+TILE_SIZE-FONT_HEIGHT, 98)
    end
  end
end
