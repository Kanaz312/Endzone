class ItemShelf
    def initialize(x, y, capacity)
        @items = []
        @capacity = capacity
        @x = x 
        @y = y
        @w = capacity * 64 + 20
        @h = 64 + 10
        @path = "sprites/shelf.png"
    end

    def primitive_marker
        return :sprite
    end

    def [](index)
        return @items[index]
    end

    def option(index)
        @option = index
    end

    def purchase_at(index, money)
        result = @items[index].can_buy(money)
        if result    
            @items[index] = @items[index].sold_sign
            @items[index].start_looking(money)
            return result
        else
            return false
        end
    end

    def <<(item)
        item.x = @x + @items.length * (64 + 5)
        item.y = @y + 10
        @items << item
    end

    def clear
        @items.clear
    end

    def draw_override(ffi_draw)
        ffi_draw.draw_sprite(@x, @y, @w, @h, @path)
        i = 0
        while i < @items.length
            @items[i].render(ffi_draw)
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
        return "ItemShelf: #{@items}"
    end

end

class Item

    TEXTX = 350
    TEXTY = 300

    attr_sprite
    def initialize(path, price, effect, description)
        @x = 0
        @y = 0
        @w = 64
        @h = 64
        @path = path + ".png"
        @green_highlight = path + "highlighted.png"
        @red_highlight = path + "redhighlight.png"
        @no_highlight = @path
        @price = price
        @effect = effect
        @can_buy = false
        @text = ""
        @description = description + " price: #{price}"
        @text_length = @description.length
    end

    def price 
        return @price
    end

    def start_looking(money)
        @can_buy = money >= @price
        if @can_buy
            @path = @green_highlight
        else
            @path = @red_highlight
        end
        @text = @description
    end

    def stop_looking
        @path = @no_highlight
        @text = ""
    end

    def apply(player)
        @effect.call(player)
    end

    def can_buy(money)
        return self if money >= @price
        return false
    end

    def sold_sign
        return Sold.new(@x, @y, @w, @h)
    end

    def render(ffi_draw)
        ffi_draw.draw_sprite(@x, @y, @w, @h, @path)
        ffi_draw.draw_label(TEXTX, TEXTY, @text, 10, 0,
                                255, 255, 255, 255, nil)
    end

end

class Sold
    attr_sprite
    def initialize(x, y, w, h)
        @x = x
        @y = y
        @w = w
        @h = h
        @path = "sprites/sold.png"
    end

    def start_looking(money)
        @path = "sprites/soldhighlighted.png"
    end

    def stop_looking
        @path = "sprites/sold.png"
    end

    def can_buy(money)
        return false
    end
    def render(ffi_draw)
        ffi_draw.draw_sprite(@x, @y, @w, @h, @path)
    end

end