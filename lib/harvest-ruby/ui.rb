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
    include Config

    def initialize(*args)
      super
      @small = Gosu::Font.new(cfg(:small_font_size))
      @big = Gosu::Font.new(cfg(:big_font_size))
      @button_pos = {}
      cfg(:pos_in_tileset).each do |action,idx|
        @button_pos[Pos.new(tgc(x+(idx*cfg(:tile_size, b: :window))), tgc(y))] = action
      end
    end

    def set_mode_if_clicked(pos)
      hit = @button_pos[pos]
      self.mode = hit unless hit.nil?
    end

    def pay
      cost = cfg(:action_cost)[self.mode]
      self.coins >= cost  ? (self.coins -= cost) : false
    end

    def draw
      # Panel Background
      (width / cfg(:tile_size, b: :window).to_f).ceil.times do |i|
        img[0].draw(x+(i*cfg(:tile_size, b: :window)),y,97)
      end

      # Panel Actions
      cfg(:pos_in_tileset).each do |ico,idx|
        pos = Pos.new(x+(idx*cfg(:tile_size, b: :window)),y)

        img[idx].draw(pos.x,pos.y,98)
        if mode == ico
          img[-1].draw(pos.x,pos.y,99,1,1,0xf0_ffffff, :additive)
          @small.draw(cfg(:action_cost)[ico].to_s+' €',pos.x+15,pos.y+35,99,1,1,cfg(:action_cost)[ico] > 0 ? 0xff_ff0000 : 0xff_088130)
        else
          @small.draw(idx,pos.x+40,pos.y+35,99,1,1,0xff_ffffff)
        end
      end

      # Currency
      @big.draw("€ " + self.coins.to_s, x+20+(cfg(:pos_in_tileset).size+1)*cfg(:tile_size, b: :window), y+cfg(:tile_size, b: :window)-cfg(:big_font_size), 98, 1, 1, 0xff_000000)

      # Day
      @big.draw("Day " + day.to_s, x+20+(cfg(:pos_in_tileset).size+4)*cfg(:tile_size, b: :window), y+cfg(:tile_size, b: :window)-cfg(:big_font_size), 98, 1, 1, 0xff_000000)
    end
  end
end
