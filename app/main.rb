require "classes/colliders.rb"
require "classes/player.rb"
require "classes/land.rb"
require "classes/enemies.rb"
require "classes/words.rb"
require "classes/gameStates.rb"
require "classes/endMenu.rb"
require "classes/items.rb"

def tick(args)
    init(args) if args.state.tick_count == 0 || args.state.reset
    change_focus = args.state.current_state.tick?(args)
    if change_focus
        args.state.current_state.focus(args)
    end
end

def init(args)
    args.state.reset = false
    args.state.items_per_shelf = 4
    args.state.money = 0
    args.state.game = Tutorial.new(args) 
    args.state.game.focus(args)
    args.state.current_state = args.state.game
    args.state.player = Player.new(33, 140, args.state.game)
    args.state.game.set_player(args.state.player, args)
    create_item_shelves(args)
    args.state.shop = Shop.new(args)
end

def create_item_shelves(args)
    item_list = []
    shelves = []
    item_list << Item.new("sprites/protein", 100, lambda {|player| player.extend_stiffarm(15)}, "Extends stiffarm duration")
    item_list << Item.new("sprites/padded_helmet", 700, lambda {|player| player.add_life}, "Provides an extra life")
    item_list << Item.new("sprites/sports_drink", 300, lambda {|player| player.reduce_cooldown(10)}, "Reduces stiffarm cooldown")
    item_list << Item.new("sprites/moon_shoes", 200, lambda {|player| player.increase_jump_height(3)}, "Increases jump height")
    start_height = 440
    i = 0
    while i < item_list.length
        if i % 4 == 0
            current_shelf = ItemShelf.new(420, start_height - (80 * (i / 4).floor), 4)
            shelves << current_shelf 
        end
        current_shelf << item_list[i]
        i += 1
    end
    args.state.items = shelves
end