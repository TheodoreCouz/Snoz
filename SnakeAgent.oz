functor

import
    OS
    System
export
    'getPort': SpawnAgent
define

    fun {FreeAround State}
        IN IS IE IW AroundI
    in
        IN = (State.y - 1)*28+State.x+1
        IS = (State.y + 1)*28+State.x+1
        IE = State.y*28+(State.x+1)+1
        IW = State.y*28+(State.x-1)+1

        AroundI = [IN#'north' IS#'south' IE#'east' IW#'west'] %North South East West

        {FreeList AroundI State.maze}

    end


    fun {Inverse Dir}
        case Dir
        of 'north' then 'south'
        [] 'south' then 'north'
        [] 'east' then 'west'
        [] 'west' then 'east'
        [] 'stopped' then 'east'
        end
    end


    fun {Random Around BadDir}
        RandNbr RandDir
    in
        RandNbr = {OS.rand} mod {List.length Around}
        RandDir = {List.nth Around RandNbr+1}
        if RandDir == BadDir then {Random Around BadDir}
        else RandDir
        end
    end


    fun {NextMove State Dir}
        I 
    in
        case Dir
        of 'north' then I = (State.y - 1)*28+State.x+1 m('x':State.x 'y':State.y-1)
        [] 'south' then I = (State.y + 1)*28+State.x+1 m('x':State.x 'y':State.y+1)
        [] 'east' then I = State.y*28+(State.x+1)+1 m('x':State.x+1 'y':State.y)
        [] 'west' then I = State.y*28+(State.x-1)+1 m('x':State.x-1 'y':State.y)
        end    
    end


    fun {FreeList AroundI Maze}
        case AroundI
        of nil then nil
        []H#Dir|T then
            if {List.nth Maze H} \= 1 then Dir|{FreeList T Maze}
            else {FreeList T Maze}
            end
        end
    end


    fun {Contains Lst Dir Acc}
        case Lst
        of nil then ~1
        [] H|T then
            if H == Dir then Acc
            else {Contains T Dir Acc+1}
            end
        end
    end


    proc {Encounter X Y Id State}
        EncounterTracker EncounterList
        proc {EncounterFilter Z ?R}
            ZId = Z.id
        in
            if {And ({Number.abs Z.x - X} < 2) ({Number.abs Z.y - Y} <2)} andthen State.tracker.ZId.type \= 'pacmoz' then R = true
            else R = false
            end
        end
    in
        EncounterTracker = {Record.filter State.tracker EncounterFilter}
        EncounterList = {Record.toList EncounterTracker} 

        for Bot in EncounterList do
     
            if Bot.alive == true then
                {Send State.gcport incense(Id Bot.id)}
            end
        end
    end


    fun {ContainsRecord  Tracker Id}
        TrackerList

        fun {ContainsRecordInner TrackerList Id}
            case TrackerList
            of nil then false
            [] Bot#R|T then
                if Bot == Id then true
                else {ContainsRecordInner T Id}
                end
            end
        end
    in
        TrackerList = {Record.toListInd Tracker} 
        {ContainsRecordInner TrackerList Id}
    end


    fun {Agent State}

        % Handle tick messages - trigger snake movement
        fun {Tick tick()}
            NextX NextY NextIndex
        in
            % Calculate next position based on current direction
            case State.dir
            of 'north' then NextX = State.x NextY = State.y - 1
            [] 'south' then NextX = State.x NextY = State.y + 1
            [] 'east' then NextX = State.x + 1 NextY = State.y
            [] 'west' then NextX = State.x - 1 NextY = State.y
            [] 'stopped' then NextX = State.x NextY = State.y
            end

            % Check for border collision (grid is 20x20, coordinates 0-19)
            if NextX < 0 orelse NextX >= 20 orelse NextY < 0 orelse NextY >= 20 then
                % Hit border - send game over message
                {System.show log(snake State.id hitBorder NextX NextY)}
                {Send State.gcport gameOver(State.id border)}
                {Agent State}
            else
                % Check for wall collision
                NextIndex = NextY * 20 + NextX + 1
                if {List.nth State.maze NextIndex} == 1 then
                    % Hit wall - send game over message
                    {System.show log(snake State.id hitWall NextX NextY)}
                    {Send State.gcport gameOver(State.id wall)}
                    {Agent State}
                else
                    % Move is valid - send moveTo message to trigger movement
                    {System.show log(snake State.id moving State.dir to NextX NextY)}
                    {Send State.gcport moveTo(State.id State.dir)}
                    {Agent State}
                end
            end
        end

        fun {MovedTo movedTo(Id Type X Y)}
            NewBot NewTracker
        in
            % Update tracker for other agents
            if State.id \= Id andthen {ContainsRecord State.tracker Id} == false then
                NewBot = bot('id':Id 'type':Type 'x':X 'y':Y 'alive':true)
                NewTracker = {AdjoinAt State.tracker Id NewBot}
            elseif State.id \= Id then
                NewBot = {Adjoin State.tracker.Id bot('x':X 'y':Y)}
                NewTracker = {AdjoinAt State.tracker Id NewBot}
            else
                NewTracker = State.tracker
            end

            % If this is our snake, update our position
            if Id == State.id then
                {System.show log(snake State.id movedTo X Y)}
                {Encounter X Y State.id State}
                {Agent {Adjoin State state('x':X 'y':Y 'tracker':NewTracker)}}
            else
                {Agent {AdjoinAt State 'tracker' NewTracker}}
            end
        end
        

        fun {PacGumSpawned Msg} {Agent State} end


        fun {PacGumDispawned Msg} {Agent State} end


        fun {PacpowSpawned Msg} {Agent State} end


        fun {PacpowDispawned Msg} {Agent State} end


        fun {PacpowDown Msg} {Agent State} end


        fun {GotHaunted gotHaunted(Id)}
            NewBot NewTracker
        in
            if Id \= State.id then
                NewBot = {AdjoinAt State.tracker.Id 'alive' false}
                NewTracker = {AdjoinAt State.tracker Id NewBot}
                {Agent {AdjoinAt State 'tracker' NewTracker}}
            else {Send State.port shutdown()} {Agent State}
            end    
        end


        fun {GotIncensed gotIncensed(Id)} 
            NewBot NewTracker
        in
            if Id \= State.id then
                NewBot = {AdjoinAt State.tracker.Id 'alive' false}
                NewTracker = {AdjoinAt State.tracker Id NewBot}
                {Agent {AdjoinAt State 'tracker' NewTracker}}
            else {Agent State} 
            end
        end


        fun {InvalidAction Msg} {Agent State} end


        fun {TellTeam Msg} {Agent State} end

        fun {BonusSpawned Msg} {Agent State} end

        fun {BonusDown Msg} {Agent State} end

        fun {BonusDispawned Msg} {Agent State} end


    in
        fun {$ Msg}
            Dispatch = {Label Msg}
            Interface = interface(
                'tick': Tick
                'movedTo': MovedTo
                'pacgumSpawned':PacGumSpawned
                'pacgumDispawned':PacGumDispawned
                'pacpowSpawned':PacpowSpawned
                'pacpowDispawned':PacpowDispawned
                'pacpowDown':PacpowDown
                'gotHaunted':GotHaunted
                'gotIncensed':GotIncensed
                'tellTeam':TellTeam
                'invalidAction':InvalidAction
                'bonusSpawned':BonusSpawned
                'bonusDispawned':BonusDispawned
                'bonusDown':BonusDown
            )
        in
            if {HasFeature Interface Dispatch} then 
                {Interface.Dispatch Msg}
            else
                {Agent State}
            end
        end
    end

    % Please note: Msg | Upcoming is a pattern match of the Stream argument
    proc {Handler Msg | Upcoming Instance}
        if Msg \= shutdown() then {Handler Upcoming {Instance Msg}} end
    end


    fun {SpawnAgent init(Id GCPort Maze X Y Orientation)}
        Stream
        Port = {NewPort Stream}

        Instance = {Agent state(
            'id': Id
            'maze': Maze
            'gcport': GCPort
            'dir':Orientation
            'x':X
            'y':Y
            'tracker':tracker()
            'port':Port
        )}
    in
        thread {Handler Stream Instance} end
        Port
    end
end
