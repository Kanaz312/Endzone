class EnemyList
    def initialize()
        @enemies = []
    end

    def primitive_marker
        return :sprite
    end

    def update_enemies
        @enemies.reject! { |enemy| enemy.update?}
    end

    def <<(enemy)
        @enemies << enemy
    end

    def clear
        @enemies.clear
    end

    def draw_override(ffi_draw)
        i = 0
        while i < @enemies.length
            @enemies[i].render(ffi_draw)
            i += 1
        end
    end

    def to_s
        return "EnemiesList: #{@enemies}"
    end
end

class Entity
    attr_sprite
    attr_accessor :x_vel, :y_vel, :collider, :y_accel, :game
    def initialize(x, y, w, h, x_vel, path, game)
            @x = x
            @y = y
            @w = w
            @h = h
            @r = 255
            @g = 255
            @b = 255
            @a = 255
            @angle = 0
            @path = path
            @x_vel = x_vel
            @y_vel = 0
            @collider = game.createCollider(x, y, w, h)
            @y_accel = -1
            @game = game
            @image_num = 0
    end

    def update?
        move(@x_vel, @y_vel)
        if @collider.right < 5
            @game.juked_player
            return true
        end    
        current_land = []
        available_land = @game.land
        i = 0
        while current_land.length == 0
            land = available_land[i]
            if @collider.left < land.left
                @game.juked_player
                return true
            end
            if land.x_inside(@collider.left)
                current_land << land
                if !land.x_inside(@collider.right) && i + 1 < available_land.length
                    current_land << available_land[i + 1]
                end
            else
                i += 1
            end
        end
        if current_land.length == 1
            delta_y = current_land[0].displacement_from_player(self)
            if delta_y > 0
                @y_vel = -1 
                @y += delta_y
                @collider.move(0, delta_y)
            else
                @y_vel += @y_accel if @y_vel > -10
            end
        else
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
                delta_y = current_land[higher_index].displacement_from_player(self)
            end
            if delta_y > -1
                @y_vel = -1 
                @y += delta_y if delta_y > 0
                @collider.move(0, delta_y)
            else
                @y_vel += @y_accel if @y_vel > -10
            end
        end
        return false
    end

    def move(dx, dy)
        @x += dx
        @y += dy
        @collider.move(dx, dy)
    end
    
    def render(ffi_draw)
        ffi_draw.draw_sprite_2(@x, @y, @w, @h, @path, @angle, @a)
        # ffi_draw.draw_solid(@collider.left, @collider.bottom, @collider.right - @collider.left, @collider.top - @collider.bottom, 255, 255, 255, 150)
    end
end

class Tackler < Entity
    def initialize(land, game)
        width = 40
        x = land.left + rand(land.w * game.tile_size - (width + 2))
        y = land.y_at(x)
        super(x, y, 40, 30, game.land_speed, "sprites/tackler0.png", game)
        @tackling = false
    end

    def dive_check(player)
        if (!@tackling) && @collider.left - player.collider.right < 20
            @path = "sprites/tackler1.png"
            @tackling = true
            @x_vel -= 2
        elsif player.still_moving?() && player.isTangible?() &&  player.collider.intersect_rect?(@collider)
            player.stop_moving
        end
    end

    def update?
        dive_check(@game.player)
        if @game.tick_count % 10 == 0 && !@tackling
            @image_num = 1 - @image_num
            @path = "sprites/tackler#{@image_num}.png"
        end
        return super
    end
end

class LineBacker < Entity
    def initialize(land, game)
        width = 40
        x = land.left + rand(land.w * game.tile_size - (width + 2))
        y = land.y_at(x)
        super(x, y, 40, 30, game.land_speed, "sprites/lineBacker0.png", game)
        @angle = 0
        @rotation = 0
    end

    def update?
        need_to_delete = super
        @angle += @rotation
        if @game.tick_count % 10 == 0
            @image_num = 1 - @image_num
            @path = "sprites/lineBacker#{@image_num}.png"
        end
        if @game.tick_count % 15 == 0
            @w += 4
            @h += 3
            @collider.scale(4, 3)
        end
        player = @game.player
        if player.collider.intersect_rect?(@collider) && player.still_moving?
            if @y_accel < 0 && player.still_moving?() && player.isTangible? && !player.stiff_arming?
                player.stop_moving
            elsif player.still_moving?
                @y_vel = 13
                @y_accel = 0
                @rotation = 5
            end
        end
        return need_to_delete
    end
end