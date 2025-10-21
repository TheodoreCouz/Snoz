functor

import
    OS
    % System
    Application
    QTk at 'x-oz://system/wp/QTk.ozf'
    State
    System
export
    'spawn': SpawnGraphics
define
    CD = {OS.getCWD}
    FONT = {QTk.newFont font('size': 18)}
    
    WALL_TILE = {QTk.newImage photo(file: CD # '/ress/wall.png')}
    GROUND_TILE = {QTk.newImage photo(file: CD # '/ress/ground.png')}

    PACMOZ_SPRITE = {QTk.newImage photo(file: CD # '/ress/pacmoz.png')}
    PACGUM_SPRITE = {QTk.newImage photo(file: CD # '/ress/pacgum.png')}
    PACPOW_SPRITE = {QTk.newImage photo(file: CD # '/ress/pacpow.png')}

    GHOST_UP_SPRITE = {QTk.newImage photo(file: CD # '/ress/ghost_up.png')}
    GHOST_DOWN_SPRITE = {QTk.newImage photo(file: CD # '/ress/ghost_down.png')}
    GHOST_RIGHT_SPRITE = {QTk.newImage photo(file: CD # '/ress/ghost_right.png')}
    GHOST_LEFT_SPRITE = {QTk.newImage photo(file: CD # '/ress/ghost_left.png')}

    SCARED_UP_SPRITE = {QTk.newImage photo(file: CD # '/ress/scared_up.png')}
    SCARED_DOWN_SPRITE = {QTk.newImage photo(file: CD # '/ress/scared_down.png')}
    SCARED_RIGHT_SPRITE = {QTk.newImage photo(file: CD # '/ress/scared_right.png')}
    SCARED_LEFT_SPRITE = {QTk.newImage photo(file: CD # '/ress/scared_left.png')}


    %HEAD
    SNAKE_HEAD_N = {QTk.newImage photo(file: CD # '/ress/head_north.png')}
    SNAKE_HEAD_E = {QTk.newImage photo(file: CD # '/ress/head_east.png')}
    SNAKE_HEAD_S = {QTk.newImage photo(file: CD # '/ress/head_south.png')}
    SNAKE_HEAD_W = {QTk.newImage photo(file: CD # '/ress/head_west.png')}

    %TAIL
    SNAKE_TAIL_N = {QTk.newImage photo(file: CD # '/ress/tail_north.png')}
    SNAKE_TAIL_E = {QTk.newImage photo(file: CD # '/ress/tail_east.png')}
    SNAKE_TAIL_S = {QTk.newImage photo(file: CD # '/ress/tail_south.png')}
    SNAKE_TAIL_W = {QTk.newImage photo(file: CD # '/ress/tail_west.png')}


    SNAKE_BODY = {QTk.newImage photo(file: CD # '/ress/body.png')}
    FRUIT = {QTk.newImage photo(file: CD # '/ress/fruit.png')}

    fun {Get_Head Dir}
        case Dir of 'EAST' then SNAKE_HEAD_E
        [] 'WEST' then SNAKE_HEAD_W
        [] 'SOUTH' then SNAKE_HEAD_S
        [] 'NORTH' then SNAKE_HEAD_N
        end
    end

    fun {Get_Tail Dir}
        case Dir of 'EAST' then SNAKE_TAIL_E
        [] 'WEST' then SNAKE_TAIL_W
        [] 'SOUTH' then SNAKE_TAIL_S
        [] 'NORTH' then SNAKE_TAIL_N
        end
    end

    class Snake

        meth init(Id Head_Loc Head_dir Tail_loc Tail_dir)

            'x_head' := Head_Loc.1
            'y_head' := Head_Loc.2.1
            'head_dir' := Head_dir

            'x_tail' := Tail_loc.1
            'y_tail' := Tail_loc.2.1
            'tail_dir' := Tail_dir

            'type' := 'snake'
            'id' := Id
            'sprite' := GROUND_TILE

            {setDirection}
        end

        meth setDirection()
                if @head_dir == 'NORTH' then
                    'sprite' := SNAKE_HEAD_N
                elseif @head_dir == 'SOUTH' then
                    'sprite' := SNAKE_HEAD_S
                elseif @head_dir == 'EAST' then
                    'sprite' := SNAKE_HEAD_E
                elseif @head_dir == 'WEST' then
                    'sprite' := SNAKE_HEAD_W
                end
        end

        meth getType($) @type end

        meth render(Buffer)
            {Buffer copy(@sprite 'to': o(@x @y))}
        end

        meth move(GCPort)
            if @head_dir == 'NORTH' then
                'y' := @y - 32
            elseif @head_dir == 'SOUTH' then
                'y' := @y + 32
            elseif @head_dir == 'EAST' then
                'x' := @x + 32
            elseif @head_dir == 'WEST' then
                'x' := @x - 32
            end

            {Send GCPort movedTo(@id @type @x @y)}
        end

        meth update(GCPort)
            {self move(GCPort)}
        end
    end

    class Graphics
        attr
            'buffer' 'buffered' 'canvas' 'window'
            'score' 'scoreHandle'
            'ids' 'gameObjects'
            'background'
            'running'
            'gcPort'
        
        meth init(GCPort)
            Height = 512
            Width = 512
        in
            'running' := true
            'gcPort' := GCPort

            'buffer' := {QTk.newImage photo('width': Width 'height': Height)}
            'buffered' := {QTk.newImage photo('width': Width 'height': Height)}

            'window' := {QTk.build td(
                canvas(
                    'handle': @canvas
                    'width': Width
                    'height': Height
                    'background': 'white'
                )
                button(
                    'text': "Close"
                    'action' : proc {$} {Application.exit 0} end
                )
            )}

            'score' := 0
            {@canvas create('image' Width div 2 Height div 2 'image': @buffer)}
            % {@canvas create('text' 128 16 'text': 'score: 0' 'fill': 'white' 'font': FONT 'handle': @scoreHandle)}
            'background' := {QTk.newImage photo('width': Width 'height': Height)}
            {@window 'show'}

            'gameObjects' := {Dictionary.new}
            'ids' := 0
        end

        meth isRunning($) @running end

        meth genId($)
            'ids' := @ids + 1
            @ids
        end

        meth spawnPacgum(X Y)
            {@background copy(PACGUM_SPRITE 'to': o(X * 32 Y * 32))}
            {Send @gcPort pacgumSpawned(X Y)}
        end

        meth dispawnPacgum(X Y)
            {@background copy(GROUND_TILE 'to': o(X * 32 Y * 32))}
            {Send @gcPort pacgumDispawned(X Y)}
        end

        meth spawnPacpow(X Y)
            {@background copy(PACPOW_SPRITE 'to': o(X * 32 Y * 32))}
            {Send @gcPort pacpowSpawned(X Y)}
        end

        meth dispawnPacpow(X Y)
            {self setAllScared(true)}
            thread
                {Delay 3000}
                {Send @gcPort pacpowDown()}
                {Delay 7000}
                {self spawnPacpow(X Y)}
            end
            {@background copy(GROUND_TILE 'to': o(X * 32 Y * 32))}
            {Send @gcPort pacpowDispawned(X Y)}
        end

        meth buildMaze(Maze)
            STATE = {State.init}
            X_head = STATE.head_loc.1
            Y_head = STATE.head_loc.2.1

            X_tail = STATE.tail_loc.1
            Y_tail = STATE.tail_loc.2.1

            X_fruit = STATE.fruit_loc.1
            Y_fruit = STATE.fruit_loc.2.1

            Head_dir = STATE.head_dir
            Tail_dir = STATE.tail_dir

            Z = {NewCell 0}
        in
            for K in Maze do
                X = @Z mod 16
                Y = @Z div 16
            in
                if K == 0 then
                    {@background copy(GROUND_TILE 'to': o(X * 32 Y * 32))}
                end
                Z := @Z + 1
            end
            {@background copy({Get_Head Head_dir} 'to': o(X_head * 32 Y_head * 32))}
            {@background copy({Get_Tail Tail_dir} 'to': o(X_tail * 32 Y_tail * 32))}
            {@background copy(FRUIT 'to': o(X_fruit * 32 Y_fruit * 32))}
        end

        meth spawnSnake(Type Head_loc Head_dir $)
            Bot
            Id = {self genId($)}

            X_head = 0 * 32
            Y_head = 1 * 32
            Head_dir = 'EAST'

            X_tail = 0 * 32
            Y_tail = 0 * 32
            Tail_dir = 'EAST'
        in
            
            Bot = {New Snake init(Id [X_head Y_head] Head_dir [X_tail Y_tail] Tail_dir)}

            {Dictionary.put @gameObjects Id Bot}
            {Send @gcPort movedTo(Id Type X Y)}
            Id
        end

        meth dispawnSnake(Id)
            {Dictionary.remove @gameObjects Id}
        end

        meth moveBot(Id Dir)
            Bot = {Dictionary.condGet @gameObjects Id 'null'}
        in
            if Bot \= 'null' then
                {Bot.move Dir}
            end
        end

        meth updateScore(Score)
            'score' := Score
            {@scoreHandle set('text': "score: " # @score)}
        end

        meth update()
            GameObjects = {Dictionary.items @gameObjects}
        in
            {@buffered copy(@background 'to': o(0 0))}
            for Gobj in GameObjects do
                {Gobj update(@gcPort)}
                {Gobj render(@buffered)}
            end
            {@buffer copy(@buffered 'to': o(0 0))}
        end
    end

    fun {NewActiveObject Class Init}
        Stream
        Port = {NewPort Stream}
        Instance = {New Class Init}
    in
        thread
            for Msg in Stream do {Instance Msg} end
        end

        proc {$ Msg} {Send Port Msg} end
    end

    fun {SpawnGraphics Port FpsMax}
        Active = {NewActiveObject Graphics init(Port)}
        FrameTime = 1000 div FpsMax
        
        proc {Ticker}
            if {Active isRunning($)} then
                {Active update()}
                {Delay FrameTime}
                {Ticker}
            end
        end
    in
        thread {Ticker} end
        Active
    end
end
