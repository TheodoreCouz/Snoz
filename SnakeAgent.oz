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


        fun {MovedTo movedTo(Id Type X Y)}    
            Around RandNbr RandDir Idx Next TempState M BadDir BadIdx NewBot NewTracker
        in
            if State.id \= Id andthen {ContainsRecord State.tracker Id} == false then
                NewBot = bot('id':Id 'type':Type 'x':X 'y':Y 'alive':true)
                NewTracker = {AdjoinAt State.tracker Id NewBot}
            elseif State.id \= Id then
                NewBot = {Adjoin State.tracker.Id bot('x':X 'y':Y)}
                NewTracker = {AdjoinAt State.tracker Id NewBot}
            else NewTracker = State.tracker
            end

            if Id == State.id then
                %if {Or {And (X == State.x) (Y == State.y)} {And (State.x == ~1) (State.y == ~1)}} then
                   
                    TempState = {Adjoin State state('x':X 'y':Y)}
                    
                    
                    Around = {FreeAround TempState}
                 
                    if {List.length Around} > 2 then
                        BadDir = {Inverse TempState.dir}
                        BadIdx = {Contains Around BadDir 1}
                        RandDir= {Random Around BadDir}
                    elseif TempState.dir == 'stopped' then
                        RandNbr = {OS.rand} mod {List.length Around}
                        RandDir = {List.nth Around RandNbr+1}
                    elseif {List.length Around} == 1 then RandDir = {List.nth Around 1}
                    else
                        M = {NextMove TempState TempState.dir}
                        Idx = {Contains Around TempState.dir 1}
                        if Idx \= ~1 then RandDir = TempState.dir 
                        else
                            BadDir = {Inverse TempState.dir}
                            BadIdx = {Contains Around BadDir 1}
                            if BadIdx == ~1 then 
                                RandNbr = {OS.rand} mod {List.length Around}
                                RandDir = {List.nth Around RandNbr+1}
                            else
                                if BadIdx == 1 then RandDir = {List.nth Around 2} 
                                else RandDir = {List.nth Around 1} 
                                end
                            end
                        end
                        
                    end

                    Next = {NextMove TempState RandDir}
                    {Send State.gcport moveTo(State.id RandDir)}  
                    {Encounter TempState.x TempState.y TempState.id TempState}
                      
                    {Agent {Adjoin TempState state('dir':RandDir 'tracker':NewTracker)}}
                % else
                %     {Agent {AdjoinAt State 'tracker' NewTracker}}
                % end
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
