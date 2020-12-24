module EndzoneLandPhysics

    def out_of_bounds?(object)
        return object.left < @land[0].left
    end

    def check_land(object)
        current_land = []
        available_land = @land
        object_left = object.left
        object_right = object.right
        i = 0
        while current_land.length == 0
            land_to_check = available_land[i]
            if land_to_check.x_inside(object_left)
                current_land << land_to_check
                if !land_to_check.x_inside(object_right) && i + 1 < available_land.length
                    current_land << available_land[i + 1]
                end
            else
                i += 1
            end
        end
        if current_land.length == 1
            # rename to y_displacement_object?
            delta_y = current_land[0].displacement_from_player(object)
        else
            #nil checks necessary?
            if current_land[0] == nil
                higher_index = 1
            elsif current_land[1] == nil
                higher_index = 0
            else
                higher_index = current_land[0].higher_land_index(current_land[1])
            end

            if current_land[0] == nil && current_land[1] == nil
                delta_y = 0
            else
                delta_y = current_land[higher_index].displacement_from_player(object)
            end
        end
        return delta_y
    end
end


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

        def intersect?(other)
            return !(@right < other.left ||
                    @left > other.right ||
                    @top < other.bottom ||
                    @bottom > other.top)
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