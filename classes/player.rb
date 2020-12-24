class PlayerList
    def initialize
        @player_stuff = []
        @player = false
    end

    def primitive_marker
        return :sprite
    end

    def add_player(player)
        @player = player
        @player_stuff << player
    end

    def player
        return @player
    end

    def update?
        @player_stuff.reject! do |object|
            remove = object.update?
            return true if remove && object == @player
            remove
        end
        return false
    end

    def <<(object)
        @player_stuff << object
    end

    def clear
        @player_stuff.clear
        @player = false
    end

    def draw_override(ffi_draw)
        i = 0
        while i < @player_stuff.length
            @player_stuff[i].render(ffi_draw)
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
        return "PlayerList: #{@player_stuff}"
    end
end

class Player
    attr_sprite
    attr_accessor :collider, :x_vel, :y_vel, :game

    def initialize(x, y, game)
        width = 32
        height = 32
        @x = x
        @y = y
        @w = width
        @h = height
        @r = 255
        @g = 255
        @b = 255
        @a = 255
        @path = "sprites/player0.png"
        @collider = game.createCollider(x, y, width, height)
        @x_vel = 0
        @y_vel = 0
        @game = game
        @x_accel = 0
        @y_accel = -1
        @jump_possible = false
        @still_moving = true
        @stiff_arm_cooldown = -30
        @stiff_arm_duration = 40
        @stiff_arm_timer = 0
        @jump_speed = 16
        @second_life = false
        @hit_already = false
        @invincibility_timer = -1
        @invincibility_duration = 60
    end

    def left
        return @collider.left
    end

    def right
        return @collider.right
    end

    def extend_stiffarm(time)
        @stiff_arm_duration += time
    end

    def reduce_cooldown(time)
        @stiff_arm_cooldown += time
    end

    def increase_jump_height(speed_increase)
        @jump_speed += speed_increase
    end

    def add_life
        @second_life = true
    end
    
    def start_position(game)
        @x = 140
        @y = 33
        @collider.move_to(140, 33)
        @x_vel = 0
        @y_vel = 0
        @x_accel = 0
        @y_accel = -1
        @still_moving = true
        @stiff_arm_timer = @stiff_arm_cooldown
        @game = game
        @image_num = 0
        @hit_already = false
    end

    def isTangible?
        return @invincibility_timer < 1
    end

    def still_moving?
        return @still_moving
    end

    def jump_possible
        return @jump_possible
    end

    def start_stiff_arm
        if @stiff_arm_timer < @stiff_arm_cooldown
            @stiff_arm_timer = @stiff_arm_duration
            @path = "sprites/player2.png"
        end
    end

    def stiff_arming?
        return @stiff_arm_timer > 0
    end

    def start_jumping
        @y_vel = @jump_speed
    end

    def stop_moving
        if @second_life && !@hit_already
            @invincibility_timer = @invincibility_duration
            @hit_already = true
        else
            @x_vel = @game.land_speed
            @still_moving = false
        end
    end

    def update?
        move(@x_vel, @y_vel)
        @stiff_arm_timer -= 1
        @invincibility_timer -= 1
        @image_num = 1 if @stiff_arm_timer == @stiff_arm_cooldown - 1
        update_image if !(stiff_arming?) && @game.tick_count % 10 == 0
        return true if @game.out_of_bounds?(self)
        delta_y = @game.check_land(self)
        if delta_y > 0
            @y_vel = -10 
            @y += delta_y
            @collider.move(0, delta_y)
        else
            @y_vel += @y_accel if @y_vel > -10
        end
        @jump_possible = delta_y > -6
        return false
    end

    def update_image
        if @stiff_arm_timer < @stiff_arm_cooldown
            @image_num = 1 - @image_num
        else
            if @image_num < 3
                @image_num = 3
            else
                @image_num = 7 - @image_num
            end
        end
        @path = "sprites/player#{@image_num}.png"
    end

    def move(dx, dy)
        @x += dx
        @y += dy
        @collider.move(dx, dy)
    end

    def ==(other)
        other.path == @path
    end

    def render(ffi_draw)
        ffi_draw.draw_sprite(@x, @y, @w, @h, @path)
        if !isTangible?
            ffi_draw.draw_sprite(@x, @y, @w, @h, "sprites/bubble.png")
        end
    end

    def serialize
        return to_s
    end

    def inspect
        return to_s
    end
    
    def to_s
        return "Player: x #{@x} y #{@y}"
    end
end