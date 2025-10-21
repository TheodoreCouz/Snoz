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

    SNAKE_HEAD_ORIGINAL = {QTk.newImage photo(file: CD # '/ress/head_east.png')}
    SNAKE_TAIL_ORIGINAL = {QTk.newImage photo(file: CD # '/ress/tail_east.png')}

    % Create rotated versions (90 degrees clockwise)
    SNAKE_HEAD = {QTk.newImage photo}
    SNAKE_TAIL = {QTk.newImage photo}
    {SNAKE_HEAD copy(SNAKE_HEAD_ORIGINAL)}
    {SNAKE_TAIL copy(SNAKE_TAIL_ORIGINAL)}
    {SNAKE_HEAD rotate(90)}
    {SNAKE_TAIL rotate(90)}
    
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

    class Snake
        attr 'id' 'type' 'headX' 'headY' 'tailX' 'tailY' 'headSprite' 'tailSprite'

        meth init(Id HeadX HeadY TailX TailY)
            'id' := Id
            'type' := 'snake'
            'headX' := HeadX
            'headY' := HeadY
            'tailX' := TailX
            'tailY' := TailY
            'headSprite' := SNAKE_HEAD
            'tailSprite' := SNAKE_TAIL
        end

        meth getType($) @type end

        meth render(Buffer)
            {Buffer copy(@headSprite 'to': o(@headX @headY))}
            {Buffer copy(@tailSprite 'to': o(@tailX @tailY))}
        end

        meth update(GCPort) skip end
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
            GridWidth = 20*32
            PanelWidth = 200
            Width = GridWidth + PanelWidth
        in
            'running' := true
            'gcPort' := GCPort

            'buffer' := {QTk.newImage photo('width': GridWidth 'height': Height)}
            'buffered' := {QTk.newImage photo('width': GridWidth 'height': Height)}

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
            {@canvas create('image' GridWidth div 2 Height div 2 'image': @buffer)}
            {@canvas create('text' GridWidth + (PanelWidth div 2) 50 'text': 'score: 0' 'fill': 'white' 'font': FONT 'handle': @scoreHandle)}
            'background' := {QTk.newImage photo('width': GridWidth 'height': Height)}
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
                % Head at (X, Y), Tail at (X, Y-1) - tail is north of head
                TailX = X * 32
                TailY = (Y - 1) * 32
                HeadX = X * 32
                HeadY = Y * 32
            in
                Bot = {New Snake init(Id HeadX HeadY TailX TailY)}
                {Dictionary.put @gameObjects Id Bot}
                {Send @gcPort movedTo(Id Type X Y)}
            end
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
