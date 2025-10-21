functor

import
    OS
    % System
    Application
    QTk at 'x-oz://system/wp/QTk.ozf'
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
    
    class GameObject
        attr 'id' 'type' 'sprite' 'x' 'y'

        meth init(Id Type Sprite X Y)
            'id' := Id
            'type' := Type
            'sprite' := Sprite
            'x' := X
            'y' := Y
        end

        meth getType($) @type end

        meth render(Buffer)
            {Buffer copy(@sprite 'to': o(@x @y))}
        end

        meth update(GCPort) skip end
    end

    class Bot from GameObject
        attr 'isMoving' 'moveDir' 'targetX' 'targetY'

        meth init(Id Type Sprite X Y)
            GameObject, init(Id Type Sprite X Y)
            'isMoving' := false
            'targetX' := X
            'targetY' := Y
        end

        meth setTarget(Dir)
            'isMoving' := true
            'moveDir' := Dir
            if Dir == 'north' then
                'targetY' := @y - 32
            elseif Dir == 'south' then
                'targetY' := @y + 32
            elseif Dir == 'east' then
                'targetX' := @x + 32
            elseif Dir == 'west' then
                'targetX' := @x - 32
            end
        end

        meth move(GCPort)
            if @moveDir == 'north' then
                'y' := @y - 4
            elseif @moveDir == 'south' then
                'y' := @y + 4
            elseif @moveDir == 'east' then
                'x' := @x + 4
            elseif @moveDir == 'west' then
                'x' := @x - 4
            end

            if @x == @targetX andthen @y == @targetY then
                NewX = @x div 32
                NewY = @y div 32
            in
                'isMoving' := false
                {Send GCPort movedTo(@id @type NewX NewY)}
            end
        end

        meth update(GCPort)
            if @isMoving then
                {self move(GCPort)}
            end
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
            Height = 20*32
            Width = 20*32
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
                    'background': 'black'
                )
                button(
                    'text': "close"
                    'action' : proc {$} {Application.exit 0} end
                )
            )}

            'score' := 0
            {@canvas create('image' Width div 2 Height div 2 'image': @buffer)}
            {@canvas create('text' 128 16 'text': 'score: 0' 'fill': 'white' 'font': FONT 'handle': @scoreHandle)}
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

        meth buildMaze(Maze)
            Z = {NewCell 0}
        in
            for K in Maze do
                X = @Z mod 20
                Y = @Z div 20
            in
                if K == 0 then
                    {@background copy(GROUND_TILE 'to': o(X * 32 Y * 32))}
                elseif K == 1 then
                    {@background copy(WALL_TILE 'to': o(X * 32 Y * 32))}
                elseif K == 2 then
                    {@background copy(GROUND_TILE 'to': o(X * 32 Y * 32))}
                end
                Z := @Z + 1
            end
        end

        meth spawnBot(Type X Y $)
            Bot
            Id = {self genId($)}
        in
            if Type == 'snake' then
                skip
            end

            {Dictionary.put @gameObjects Id Bot}
            {Send @gcPort movedTo(Id Type X Y)}
            Id
        end

        meth dispawnBot(Id)
            {Dictionary.remove @gameObjects Id}
        end

        meth moveBot(Id Dir)
            Bot = {Dictionary.condGet @gameObjects Id 'null'}
        in
            if Bot \= 'null' then
                {Bot setTarget(Dir)}
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
