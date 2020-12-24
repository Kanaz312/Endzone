class LandList
    def initialize(game)
        @land = []
        @length = 0
        @game = game
    end

    def primitive_marker
        return :sprite
    end

    def update_land
        land_speed = @game.land_speed
        @land.reject! { |land| land.move?(land_speed) }
    end

    def <<(land)
        @land << land
        @length += 1
    end

    def clear
        @land.clear
    end

    def [](index)
        return @land[index]
    end

    def length()
        return @length
    end
    
    def draw_override(ffi_draw)
        i = 0
        while i < @land.length
            @land[i].render(ffi_draw)
            i += 1
        end
    end

    def to_s
        return "LandList: #{@land}"
    end
end

class Land
    TILESIZE = 32
    #width/height given in tiles
    attr_accessor :w, :h, :left, :generation_frame, :game
    def initialize(start, w, h, generation_frame, game)
        @w = w
        @h = h
        @left = start
        @generation_frame = generation_frame
        @game = game
    end

    def x_inside(x)
        return x >= @left && x <= @left + (@w * TILESIZE) 
    end
end

class FlatLand < Land

    TILESIZE = 32
    #width/height given in tiles
    def initialize(start, w, h, generation_frame, game)
        super(start, w, h, generation_frame, game)
    end

    def ==(other)
        return other.class == FlatLand && @generation_frame == other.generation_frame
    end

    def render(ffi_draw)
        top_layer_y = (@h - 1) * TILESIZE
        left = @left
        @w.times do |col|
            ffi_draw.draw_sprite(left + (col * TILESIZE), top_layer_y, TILESIZE, TILESIZE,
                                    "sprites/grassFlat.png") if left + (col * TILESIZE) < 1280 && left + ((col + 1) * TILESIZE) > 0
        end
        @w.times do |col|
            (@h - 1).times do |row|
                ffi_draw.draw_sprite(left + (col * TILESIZE), row * TILESIZE,TILESIZE, TILESIZE, 
                                        "sprites/dirt.png") if left + (col * TILESIZE) < 1280 && left + ((col + 1) * TILESIZE) > 0
            end
        end
    end

    def move?(dx)
        @left += dx
        #should be 0 but shifting bug means this needs to change
        return @left + (@w * TILESIZE) < -2
    end

    def displacement_from_player(player)
        return @h * TILESIZE - player.y 
    end

    def y_at(x)
        return @h * TILESIZE
    end
    
    def new_starting_point
        return @h
    end

    def higher_land_index(other)
        if other.isUpLand
            return 1
        else
            return 0
        end
    end

    def isUpLand
        return false
    end

    def isFlat
        return true
    end

    def to_s
        return "FlatLand [left: #{@left}, h: #{@h}, w: #{@w}"
    end

end

class UpLand < Land
    TILESIZE = 32
    #width/height given in tiles
    def initialize(start, w, h, generation_frame, game)
        super(start, w, h, generation_frame, game)
    end

    def ==(other)
        return other.class == UpLand && @generation_frame == other.generation_frame
    end

    def render(ffi_draw)
        height = @h
        left = @left
        @w.times do |col|
            (height + col).times do |row|
                ffi_draw.draw_sprite(left + (col * TILESIZE), row * TILESIZE, TILESIZE, TILESIZE, 
                                        "sprites/dirt.png") if left + (col * TILESIZE) < 1280 && left + ((col + 1) * TILESIZE) > 0
            end
            ffi_draw.draw_sprite(left + (col * TILESIZE), (height + col) * TILESIZE, TILESIZE, TILESIZE,
                                    "sprites/grassUp.png") if left + (col * TILESIZE) < 1280 && left + ((col + 1) * TILESIZE) > 0
        end
    end

    def move?(dx)
        @left += dx
        #should be 0 but shifting bug means this needs to change
        return @left + (@w * TILESIZE) < -2
    end

    def displacement_from_player(player)
        local_distance_from_left = player.collider.right.round - @left
        player_column = (local_distance_from_left / TILESIZE).floor()
        new_y = (local_distance_from_left % TILESIZE) + (@h + player_column) * TILESIZE
        return new_y - player.y
    end

    def y_at(x)
        local_distance_from_left = x - @left
        player_column = (local_distance_from_left / TILESIZE).floor()
        return (local_distance_from_left % TILESIZE) + (@h + player_column) * TILESIZE
    end

    def new_starting_point
        return @h + @w
    end

    def higher_land_index(other)
        return 1
    end

    def isUpLand
        return true
    end

    def isFlat
        return false
    end

    def to_s
        return "UpLand [left: #{@left}, h: #{@h}, w: #{@w}"
    end
end

class DownLand < Land
    TILESIZE = 32
    #width/height given in tiles
    def initialize(start, w, h, generation_frame, game)
        super(start, w, h, generation_frame, game)
    end

    def ==(other)
        return other.class == FlatLand && @generation_frame == other.generation_frame
    end

    def render(ffi_draw)
        height = @h - 1
        left = @left
        @w.times do |col|
            (height - col).times do |row|
                ffi_draw.draw_sprite(left + (col * TILESIZE), row * TILESIZE, TILESIZE, TILESIZE, 
                                        "sprites/dirt.png") if left + (col * TILESIZE) < 1280 && left + ((col + 1) * TILESIZE) > 0
            end
            ffi_draw.draw_sprite(left + (col * TILESIZE), (height - col) * TILESIZE, TILESIZE, TILESIZE,
                                    "sprites/grassDown.png") if left + (col * TILESIZE) < 1280 && left + ((col + 1) * TILESIZE) > 0
        end
    end

    def move?(dx)
        @left += dx
        return @left + (@w * TILESIZE) < 0
    end

    def displacement_from_player(player)
        local_distance_from_left = player.collider.left - @left
        player_column = (local_distance_from_left / TILESIZE).floor()
        new_y = ((@h - player_column) * TILESIZE) - (local_distance_from_left % TILESIZE)
        return new_y - player.y
    end

    def y_at(x)
        local_distance_from_left = x - @left
        column = (local_distance_from_left / TILESIZE).floor()
        return ((@h - column) * TILESIZE) - (local_distance_from_left % TILESIZE)
    end

    def new_starting_point
        return @h - @w
    end

    def higher_land_index(other)
        return 0
    end

    def isUpLand
        return false
    end

    def isFlat
        return false
    end

    def to_s
        return "DownLand [left: #{@left}, h: #{@h}, w: #{@w}"
    end
end