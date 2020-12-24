class Game
    include RectangleColliders

    attr_accessor :tile_size, :distance, :reset, :tick_count, :run_ended, :display_end, 
                    :enemies_juked, :land, :land_speed, :last_land, :enemies, :player, :words


    def initialize(args)
        @tile_size = 32
        @distance = 0
        @reset = false
        @tick_count = 0
        @run_ended = false
        @display_end = false
        @enemies_juked = 0
        @stadium_x = 0
    end

    def focus(args)
        # make flat land across screen to start
        args.outputs.static_sprites.clear
        @land = LandList.new(self)
        args.outputs.static_sprites << @land
        first_land = FlatLand.new(0, 40, 1, @tick_count, self)
        @land << first_land
        # queue a slope up as well
        new_land = UpLand.new(first_land.left + (first_land.w * @tile_size), 6 + rand(6), 1, @tick_count, self)
        @land << new_land
        @land_speed = -6
        @last_land = new_land
        @enemies = EnemyList.new
        args.outputs.static_sprites << @enemies
        @player_list = PlayerList.new
        args.state.player.start_position(self)
        @player = args.state.player
        @player_list.add_player(@player)
        args.outputs.static_sprites << @player_list
        @words = WordList.new
        args.outputs.static_sprites << @words
        @end_menu = []
        args.outputs.sounds << "music/runmusic.ogg"
    end

    def set_player(player, args)
        @player_list.clear
        args.state.player.start_position(self)
        @player = player
        @player_list.add_player(@player)
    end

    def tick?(args)
        prep_end_menu(args) if @run_ended
        if @display_end
            if @end_menu.update?(args.inputs.keyboard)
                args.state.money += @end_menu.money_earned
                if @end_menu.shop?
                    args.state.current_state = args.state.shop
                    return true
                elsif @end_menu.retry?
                    args.state.current_state = Game.new(args)
                    args.state.current_state.focus(args)
                end
            end
            render_labels(args)
        else
            player_input(args.inputs.keyboard)
            update
            render_labels(args)
            @distance += 1 if @tick_count % 60 == 0 && @player.still_moving? 
            if @tick_count % 2 == 0
                @stadium_x = (@stadium_x + 1) % 1280
            end
        end
        args.outputs.sprites << {x: 0, y: 0, w: 1280, h: 720, path: "sprites/sky.png", tile_x: @stadium_x % 2560,
                                 tile_y: 0, tile_w: 1280, tile_h: 720}
        @tick_count += 1
        return false
    end
    
    def prep_end_menu(args)
        @end_menu = EndMenu.new(@enemies_juked, @distance, args.state.money)
        args.outputs.static_sprites << @end_menu
        @display_end = true
        @run_ended = false
        @words.clear
        @enemies.clear
        @player_list.clear
    end

    def juked_enemy
        @enemies_juked += 1
    end

    def player_input(keyboard)
        # register jump
        player = @player
        if keyboard.key_down.up && player.jump_possible && player.still_moving?
            player.start_jumping
        end
        if keyboard.key_down.right
            player.start_stiff_arm
        end

        @words.register_letters(keyboard.truthy_keys)
    end
    
    def update
        @land.update_land
        @enemies.update_enemies
        @run_ended = true if @player_list.update?
        generate_new_land
        (1 + rand(@distance / 10)).floor().times do |i|
            if @distance % 10 == 9 && tick_count % 60 == 2
                @words.new_word(@distance > 150)
            end
        end
    end
    
    def generate_new_land
        if 1280 - @last_land.left > @last_land.w - 2
            tile_size = @tile_size
            last_land = @last_land
            if rand(2) == 0 && last_land.isFlat
                starting_point = last_land.new_starting_point
                if starting_point > 13
                    new_land = DownLand.new(last_land.left + (last_land.w * tile_size), 6 + rand(6),
                                            starting_point, @tick_count, self)
                elsif starting_point < 7
                    new_land = UpLand.new(last_land.left + (last_land.w * tile_size), 3 + rand(3),
                                            starting_point, @tick_count, self)
                else
                    if rand(2) == 0
                        new_land = UpLand.new(last_land.left + (last_land.w * tile_size), 3 + rand(3),
                                             starting_point, @tick_count, self)
                    else
                        new_land = DownLand.new(last_land.left + (last_land.w * tile_size), 3 + rand(3),
                                                starting_point, @tick_count, self)
                    end
                end
            else
                new_land = FlatLand.new(last_land.left + (last_land.w * tile_size), 6 + rand(6),
                                         last_land.new_starting_point, @tick_count, self)
            end
            if rand(3) == 0 && !(new_land.isUpLand)
                @enemies << Tackler.new(new_land, self)
            end
    
            if rand(4) == 0
                @enemies << LineBacker.new(new_land, self)
            end
            @land << new_land
            @last_land = new_land
        end
    end
    
    def render_labels(args)
        args.outputs.labels << [0, 720, "fps: #{args.gtk.current_framerate.to_s.to_i}"]
        args.outputs.labels << [0, 700, "yards: #{@distance}"]
    end

    def serialize
        return to_s
    end

    def inspect
        return to_s
    end
    
    def to_s
        return "Game"
    end
end

class Shop
    def initialize(args)
        @shelves = args.state.items
        @items_per_shelf = args.state.items_per_shelf
        @money = args.state.money
        @row = 0
        @col = 0
        @shelves[@row][@col].start_looking(@money)
        #@exit_sign = []
    end

    def primitive_marker
        :sprite
    end

    def tick?(args)
        focus(args) if args.inputs.keyboard.key_down.r
        if player_input?(args.inputs.keyboard, args)
            args.state.current_state = Game.new(args)
            return true
        end
        render_credits(args)
        return false
    end

    def focus(args)
        args.outputs.static_sprites.clear
        args.outputs.static_sprites << [0, 0, 1280, 720, "sprites/shack.png"]
        i = 0
        while i < @shelves.length
            args.outputs.static_sprites << @shelves[i]
            i += 1
        end
        args.outputs.static_sprites << [800, 400, 100, 50, "sprites/retry.png"]
        @money = args.state.money
        @shelves[@row][@col].stop_looking if @col < @items_per_shelf
        @row = 0
        @col = 0
        @shelves[0][0].start_looking(@money)
    end

    def player_input?(keyboard, args)
        if keyboard.truthy_keys.length != 0
            old_col = @col
            @shelves[@row][@col].stop_looking if @col < @items_per_shelf
            @row += 1 if keyboard.key_down.down && @row < @shelves.length - 1
            @row -= 1 if keyboard.key_down.up && @row > 0
            @col += 1 if keyboard.key_down.right && @col < @items_per_shelf
            @col -= 1 if keyboard.key_down.left && @col > 0
            @shelves[@row][@col].start_looking(@money) if @col < @items_per_shelf
            if @col == @items_per_shelf
                args.outputs.static_sprites.delete_at(args.outputs.static_sprites.length - 1)
                args.outputs.static_sprites << [800, 400, 100, 50, "sprites/retryhighlighted.png"]
            elsif old_col == @items_per_shelf
                args.outputs.static_sprites.delete_at(args.outputs.static_sprites.length - 1)
                args.outputs.static_sprites << [800, 400, 100, 50, "sprites/retry.png"]
            end
            if keyboard.key_down.enter && @col < @items_per_shelf
                purchased_item = @shelves[@row].purchase_at(@col, @money)
                if purchased_item
                    @money -= purchased_item.price
                    args.state.money -= purchased_item.price
                    purchased_item.apply(args.state.player)
                end
            elsif keyboard.key_down.enter
                return true
            end
            return false
        end
    end

    def render_credits(args)
        args.outputs.labels << [255, 135, "player, enemy, and ground assets: @KennyNL ", 5]
        args.outputs.labels << [255, 100, "music: \"Faster stronger harder\" by Nicolas Jeudy", 5]
    end
end

class Tutorial
    include RectangleColliders

    attr_accessor :tile_size, :distance, :reset, :tick_count, :run_ended, :display_end, 
    :enemies_juked, :land, :land_speed, :last_land, :enemies, :player, :words

    def initialize(args)
        @tile_size = 32
        @distance = 0
        @reset = false
        @tick_count = 0
        @run_ended = false
        @display_end = false
        @enemies_juked = 0
        @tutorial_text = ["Press up to jump", "Jump over the tacklers", "Press right to stiffarm", "Notice the cooldown",
                        "Stiffarm linebackers to push through them", "Words will try to distract you", 
                        "Type out the words to clear them", "That's all! Good luck"]
        @text_index = 0
        @jumped = false
        @cleared_enemy = false
        @spawn_enemy = false
        @spawn_word = false
        @stiff_armed = false
        @typed = false
        @text_timer = -1
        @text_duration = 120 
    end

    def focus(args)
        # make flat land across screen to start
        args.outputs.static_sprites.clear
        @land = LandList.new(self)
        args.outputs.static_sprites << @land
        first_land = FlatLand.new(0, 20, 1, @tick_count, self)
        @land << first_land
        # queue a slope up as well
        new_land = FlatLand.new(first_land.left + (first_land.w * @tile_size), 20, 1, @tick_count, self)
        @land << new_land
        @land_speed = -6
        @last_land = new_land
        @enemies = EnemyList.new
        args.outputs.static_sprites << @enemies
        @player_list = PlayerList.new
        args.state.player.start_position(self)
        @player = args.state.player
        @player_list.add_player(@player)
        args.outputs.static_sprites << @player_list
        @words = WordList.new
        args.outputs.static_sprites << @words
        @end_menu = []
    end

    def set_player(player, args)
        @player_list.clear
        args.state.player.start_position(self)
        @player = player
        @player_list.add_player(@player)
    end

    def tick?(args)
        player_input(args.inputs.keyboard)
        return true if update?(args)
        render_labels(args)
        @distance += 1 if @tick_count % 60 == 0 && @player.still_moving? 
        @tick_count += 1
        return false
    end

    def prep_end_menu(args)
        @end_menu = EndMenu.new(@enemies_juked, @distance, args.state.money)
        args.outputs.static_sprites << @end_menu
        @display_end = true
        @run_ended = false
        @words.clear
        @enemies.clear
        @player_list.clear
    end

    def juked_enemy
        @enemies_juked += 1
        @cleared_enemy = true
    end

    def player_input(keyboard)
        # register jump
        player = @player
        if keyboard.key_down.up && player.jump_possible && player.still_moving?
            player.start_jumping
            if !@jumped
                update_text 
                @spawn_enemy = true
                @jumped = true
            end
        end

        if keyboard.key_down.right
            player.start_stiff_arm
            if @jumped && !@stiff_armed && @enemies_juked == 1
                update_text 
                @stiff_armed = true
                @text_timer = @text_duration
            end
        end

        if @words.register_letters?(keyboard.truthy_keys)
            if @stiff_armed && @text_index == 6 && !@typed
                @text_timer = @text_duration
                @typed = true
            end
        end
    end

    def update_text
        @text_index += 1
    end

    def update?(args)
        @land.update_land
        @enemies.update_enemies
        @run_ended = true if @player_list.update?
        generate_new_land
        @text_timer -= 1
        if @cleared_enemy
            update_text
            @cleared_enemy = false
            @text_timer = @text_duration if @stiff_armed
        end
        if @text_timer == 0
            if @text_index == 4
                @text_timer = @text_duration
            elsif @text_index == 5
                @words.new_word(false)
            elsif @text_index == 6
                @text_timer = @text_duration
            elsif @typed
                args.state.current_state = Game.new(args)
                return true
            elsif @stiff_armed
                @spawn_enemy = true
            end
            update_text
        end
        return false
    end

    def generate_new_land
        if 1280 - @last_land.left > @last_land.w - 2
            tile_size = @tile_size
            last_land = @last_land
            new_land = FlatLand.new(last_land.left + (last_land.w * tile_size), 20,
                last_land.new_starting_point, @tick_count, self)
            if @jumped && !@stiff_armed && @spawn_enemy
                puts "added"
                @enemies << Tackler.new(new_land, self)
                @spawn_enemy = false
            end
            if @stiff_armed && @spawn_enemy
                @enemies << LineBacker.new(new_land, self)
                @spawn_enemy = false
            end
            @land << new_land
            @last_land = new_land
        end
    end

    def render_labels(args)
        args.outputs.labels << [0, 720, "fps: #{args.gtk.current_framerate.to_s.to_i}"]
        args.outputs.labels << [0, 700, "yards: #{@distance}"]
        size_values = args.gtk.calcstringbox(@tutorial_text[@text_index], 10)
        w = size_values[0]
        h = size_values[1]
        args.outputs.labels << [(1280 - w) / 2, (720 - h) / 2, @tutorial_text[@text_index], 10, 0]
    end

    def serialize
        return to_s
    end

    def inspect
        return to_s
    end

    def to_s
        return "Tutorial"
    end
end