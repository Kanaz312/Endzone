class EndMenu
    def initialize(players_juked, distance, money)
        @money_earned = (players_juked * 2) + (distance / 10).floor
        @total_money = money + @money_earned
        @text =  ["Players juked: #{players_juked}", "Distance: #{distance} yards", 
                    "Money earned: #{@money_earned}", "Total money: #{@total_money}", "Shop", "Retry"]
        @text_size = [10, 35]
        @text_distance = @text_size[1] + 20
        @option = 4
        @width = 600
        @height = 400
        @x = (1280 - @width) / 2
        @y = (720 - @height) / 2
    end

    def primitive_marker
        return :label
    end

    def money_earned
        return @money_earned
    end

    def update?(keyboard)
        @option += 1 if keyboard.key_down.down && @option == 4
        @option -= 1 if keyboard.key_down.up && @option == 5
        return keyboard.key_down.enter
    end

    def shop?
        return @text[@option] == "Shop"
    end

    def retry?
        return @text[@option] == "Retry"
    end

    def draw_override(ffi_draw)
        ffi_draw.draw_solid(@x, @y, @width, @height, 180, 180, 180, 255)
        starting_height = @y + @height - 20
        if @option == 4
            ffi_draw.draw_solid(@x + 20, starting_height - ((@text_distance - 4) * (@option + 1)), 
                                @text[@option].length * 20, 30, 255, 255, 255, 150)
        elsif @option == 5
            ffi_draw.draw_solid(@x + 20, starting_height - ((@text_distance - 3.5) * (@option + 1)), 
                                @text[@option].length * 20, 30, 255, 255, 255, 150)
        end
        
        i = 0
        while i < @text.length
            # l.x, l.y, l.text.s_or_default, l.size_enum, l.alignment_enum,
            #  l.r, l.g, l.b, l.a, l.font.s_or_default(nil)
            ffi_draw.draw_label(@x + 20, starting_height - (@text_distance * i), @text[i], @text_size[0], 0,
                                255, 255, 255, 255, nil)
            i += 1
        end
    end

    def serialize
        return to_s
    end

    def inspect
        return to_s
    end
    
    def to_s
        return "End Menu: option #{@option} menu_length: #{@text.length}"
    end
end