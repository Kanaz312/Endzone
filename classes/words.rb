class WordList
    def initialize
        @words = []
    end

    def primitive_marker
        return :sprite
    end

    def register_letters(letters)
        letters.each_index {|i| letters[i] = letters[i].to_s}
        @words.reject! do |word|
            finished = word.register_letters?(letters)
            word.update if !finished
            finished
        end
    end

    def register_letters?(letters)
        letters.each_index {|i| letters[i] = letters[i].to_s}
        @words.reject! do |word|
            finished = word.register_letters?(letters)
            word.update if !finished
            finished
        end
        return @words.length == 0
    end

    def <<(word)
        @words << word
    end

    def clear
        @words.clear
    end

    def new_word(hard_possible)
        if hard_possible && rand(3) == 0
            @words << Word.new(false)
        else 
            @words << Word.new(true)
        end
    end

    def draw_override(ffi_draw)
        i = 0
        while i < @words.length
            @words[i].render(ffi_draw)
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
        return "WordsList: #{@words}"
    end
end

class Word

    EASYWORDS = ["stacy", "rent", "grades", "pizza", "finals", "boba", "ramen"]
    HARDWORDS = ["mathematics", "chemistry", "pepperoni", "partying", "classroom", "pogchamp"]
    TRUNCATEDWORDS = ["math", "mom", "chem", "pizza", "party", "covid", "class", "pog"]

    def initialize(easy)
        if easy
            @word = EASYWORDS.sample
        else
            @word = HARDWORDS.sample
        end
        @length = @word.length
        @typed = 0
        @x = rand(1080)
        @y = rand(620)
        @w = 200
        @h = 100
        @a = 100
        @x_vel = 1 + rand(3)
        @y_vel = 1 + rand(3)
    end

    def register_letters?(letters)
        i = 2
        # may want to only allow one letter to be resolved
        while i < letters.length
            if letters[i] == @word[@typed]
                @typed += 1
            end
            i += 1
        end
        return @typed == @length
    end

    def update
        @x += @x_vel
        @y += @y_vel
        if @x < 0
            @x_vel = -@x_vel
            @x = 0
        elsif @x > 1080
            @x_vel = -@x_vel
            @x = 1080
        end
        if @y < 0 
            @y_vel = -@y_vel
            @y = 0
        elsif @y > 620
            @y_vel = -@y_vel
            @y = 620
        end
        @a += 1
        @w += 1 if @w < 500
        @h += 0.5 if @h < 250
    end

    def render(ffi_draw)
        # x, y, w, h, path, angle, alpha
        ffi_draw.draw_sprite_2(@x, @y, @w, @h, "words/#{@word}#{@typed}.png", 0, @a,)
    end

    def serialize
        return to_s
    end

    def inspect
        return to_s
    end
    
    def to_s
        return @word
    end
end