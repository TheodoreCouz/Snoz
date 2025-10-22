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

    % Snake 1: sprites
    SNAKE1_HEAD = head(
        'EAST': {QTk.newImage photo(file: CD # '/ress/head_east.png')}
        'SOUTH': {QTk.newImage photo(file: CD # '/ress/head_south.png')}
        'WEST': {QTk.newImage photo(file: CD # '/ress/head_west.png')}
        'NORTH': {QTk.newImage photo(file: CD # '/ress/head_north.png')}
        )
    SNAKE1_TAIL = tail(
        'EAST': {QTk.newImage photo(file: CD # '/ress/tail_east.png')}
        'SOUTH': {QTk.newImage photo(file: CD # '/ress/tail_south.png')}
        'WEST': {QTk.newImage photo(file: CD # '/ress/tail_west.png')}
        'NORTH': {QTk.newImage photo(file: CD # '/ress/tail_north.png')}
        )

    % Snake 2: sprites
    SNAKE2_HEAD = head(
        'EAST': {QTk.newImage photo(file: CD # '/ress/head2_east.png')}
        'SOUTH': {QTk.newImage photo(file: CD # '/ress/head2_south.png')}
        'WEST': {QTk.newImage photo(file: CD # '/ress/head2_west.png')}
        'NORTH': {QTk.newImage photo(file: CD # '/ress/head2_north.png')}
        )
    SNAKE2_TAIL = tail(
        'EAST': {QTk.newImage photo(file: CD # '/ress/tail2_east.png')}
        'SOUTH': {QTk.newImage photo(file: CD # '/ress/tail2_south.png')}
        'WEST': {QTk.newImage photo(file: CD # '/ress/tail2_west.png')}
        'NORTH': {QTk.newImage photo(file: CD # '/ress/tail2_north.png')}
        )

TAIL_OFFSET = offset(
    'EAST': offset('x': ~1 'y': 0)
    'SOUTH': offset('x': 0 'y': ~1)
    'WEST': offset('x': 1 'y': 0)
    'NORTH': offset('x': 0 'y': 1)
)
    
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
        attr 'id' 'type' 'headX' 'headY' 'tailX' 'tailY' 'headSprite' 'tailSprite' 'headOri' 'tailOri'
             'isMoving' 'moveDir' 'targetHeadX' 'targetHeadY' 'targetTailX' 'targetTailY'

        meth init(Id Type HeadX HeadY TailX TailY Orientation)
            'id' := Id
            'type' := Type
            'headX' := HeadX
            'headY' := HeadY
            'tailX' := TailX
            'tailY' := TailY
            'headOri' := Orientation
            'tailOri' := Orientation
            'isMoving' := false
            'targetHeadX' := HeadX
            'targetHeadY' := HeadY
            'targetTailX' := TailX
            'targetTailY' := TailY

            if Type == 'snake' then
                'headSprite' := SNAKE1_HEAD
                'tailSprite' := SNAKE1_TAIL
            elseif Type == 'snake2' then
                'headSprite' := SNAKE2_HEAD
                'tailSprite' := SNAKE2_TAIL
            else skip
            end
        end

        meth getType($) @type end

        meth setTarget(Dir)
            'isMoving' := true
            'moveDir' := Dir

            % Convert direction string to uppercase for sprite access
            UpperDir = case Dir
                       of 'north' then 'NORTH'
                       [] 'south' then 'SOUTH'
                       [] 'east' then 'EAST'
                       [] 'west' then 'WEST'
                       else 'EAST'
                       end

            'headOri' := UpperDir
            'tailOri' := UpperDir

            if Dir == 'north' then
                'targetHeadY' := @headY - 32
                'targetTailY' := @tailY - 32
            elseif Dir == 'south' then
                'targetHeadY' := @headY + 32
                'targetTailY' := @tailY + 32
            elseif Dir == 'east' then
                'targetHeadX' := @headX + 32
                'targetTailX' := @tailX + 32
            elseif Dir == 'west' then
                'targetHeadX' := @headX - 32
                'targetTailX' := @tailX - 32
            end
        end

        meth move(GCPort)
            if @moveDir == 'north' then
                'headY' := @headY - 4
                'tailY' := @tailY - 4
            elseif @moveDir == 'south' then
                'headY' := @headY + 4
                'tailY' := @tailY + 4
            elseif @moveDir == 'east' then
                'headX' := @headX + 4
                'tailX' := @tailX + 4
            elseif @moveDir == 'west' then
                'headX' := @headX - 4
                'tailX' := @tailX - 4
            end

            if @headX == @targetHeadX andthen @headY == @targetHeadY then
                NewX = @headX div 32
                NewY = @headY div 32
            in
                'isMoving' := false
                {Send GCPort movedTo(@id @type NewX NewY)}
            end
        end

        meth render(Buffer)
            {Buffer copy(@headSprite.@headOri 'to': o(@headX @headY))}
            {Buffer copy(@tailSprite.@tailOri 'to': o(@tailX @tailY))}
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

        meth spawnBot(Type X Y Orientation $)
            Bot
            Id = {self genId($)}
        in
            local
                % Head at (X, Y), Tail at (X, Y-1) - tail is north of head
                TailX = (X + TAIL_OFFSET.Orientation.'x') * 32
                TailY = (Y + TAIL_OFFSET.Orientation.'y') * 32
                HeadX = X * 32
                HeadY = Y * 32
            in
                Bot = {New Snake init(Id Type HeadX HeadY TailX TailY Orientation)}
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

        meth stopGame()
            'running' := false
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
