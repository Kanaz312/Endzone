module RectangleColliders 
    def createCollider(x, y, w, h)
        return Rectangle.new(x, y, w, h)
    end

    class Rectangle
        # attr_sprite
        include GTK::Geometry
        attr_accessor :x, :y, :w, :h, :right, :left, :top, :bottom
        def initialize(x, y, w, h)
            @x = x 
            @y = y
            @w= w
            @h = h
            @right = @x + @w
            @left = @x
            @top = @y + @h
            @bottom = @y
        end

        def move_to(x, y)
            @x = x
            @y = y
            @right = x + @w
            @left = x
            @top = y + @h
            @bottom = y
        end

        def move(dx, dy)
            @x += dx
            @y += dy
            @right += dx
            @left += dx
            @top += dy
            @bottom += dy
        end

        def scale(dx, dy)
            @right += dx
            @top += dy
        end

        def intersect_rect?(other)
            return !(@right < other.left ||
                    @left > other.right ||
                    @top < other.bottom ||
                    @bottom > other.top)
        end

        def to_hash
            return {class: "rectangle", x: @x, y: @y, w: @w, h: @h}
        end

        def to_array
            return [@x, @y, @w, @h]
        end

        def serialize
            hash = {class: "rectangle", x: @x, y: @y, w: @w, h: @h}
            return hash
        end
        
        def inspect
            serialize.to_s
        end

        def to_s
            return "rectangle: #{serialize.to_s}"
        end
    end
end