functor

import
    Input
    System
    Graphics
    AgentManager
    Application
define
     % Check the Adjoin and AdjoinAt function, documentation: (http://mozart2.org/mozart-v1/doc-1.4.0/base/record.html#section.records.records)

    proc {Broadcast Tracker Msg}
        {Record.forAll Tracker proc {$ Tracked} if Tracked.alive then {Send Tracked.port Msg} end end}
    end

    % Convert orientation from uppercase to lowercase
    fun {OrientationToLower Ori}
        case Ori of 'EAST' then 'east'
        [] 'WEST' then 'west'
        [] 'NORTH' then 'north'
        [] 'SOUTH' then 'south'
        else Ori
        end
    end

    % Complete this concurrent functional agent to handle all the message-passing between the GUI and the Agents
    fun {GameController State}
        fun {MoveTo moveTo(Id Dir)}
            {State.gui moveBot(Id Dir)}
            {GameController State}
        end

        % function to handle the PacGumSpawned message
        fun {PacgumSpawned pacgumSpawned(X Y)}
            Index = Y * 28 + X
            NewItems = {Adjoin State.items items(Index: gum('alive': true) 'ngum': State.items.ngum + 1)}
        in
            {Broadcast State.tracker pacgumSpawned(X Y)}
            {GameController {AdjoinAt State 'items' NewItems}}
        end

        % function to handle the movedTo message
        fun {MovedTo movedTo(Id Type X Y)}
            {System.show log(movedTo Id Type X Y)}

            % Broadcast to all agents
            {Broadcast State.tracker movedTo(Id Type X Y)}

            % Update tracker with new position
            if {HasFeature State.tracker Id} then
                UpdatedBot = {AdjoinAt State.tracker.Id 'x' X}
                UpdatedBot2 = {AdjoinAt UpdatedBot 'y' Y}
                NewTracker = {AdjoinAt State.tracker Id UpdatedBot2}
            in
                {GameController {AdjoinAt State 'tracker' NewTracker}}
            else
                {GameController State}
            end
        end

        % function to handle the gameOver message
        fun {GameOver gameOver(Id)}
            {System.show 'Game Over - Snake '#Id#' hit a border or wall'}
            {Application.exit 0}
            {GameController State}
        end
    in
        % TODO: complete the interface and discard and report unknown messages
        % every function is a field in the interface() record
        fun {$ Msg}
            Dispatch = {Label Msg}
            Interface = interface(
                'moveTo': MoveTo
                'movedTo': MovedTo
                'pacgumSpawned': PacgumSpawned
                'gameOver': GameOver
            )
        in
            if {HasFeature Interface Dispatch} then
                {Interface.Dispatch Msg}
            else
                {System.show log('Unhandled message' Dispatch)}
                {GameController State}
            end
        end
    end

    % Please note: Msg | Upcoming is a pattern match of the Stream argument
    proc {Handler Msg | Upcoming Instance}
        {Handler Upcoming {Instance Msg}}
    end

    % Spawn the agents
    proc {StartGame}
        Stream
        Port = {NewPort Stream}
        GUI = {Graphics.spawn Port 30}

        Maze = {Input.genMaze}
        {GUI buildMaze(Maze)}

        % Spawn all bots from Input configuration
        Bots = Input.bots
        Tracker = tracker()
        NewTracker

        fun {SpawnBots BotList CurrentTracker}
            case BotList of nil then CurrentTracker
            [] Bot|Rest then
                case Bot of bot(Type Name X Y Orientation) then
                    % Spawn the visual representation
                    BotId = {GUI spawnBot(Type X Y Orientation $)}
                    % Spawn the agent logic with lowercase orientation
                    LowerOri = {OrientationToLower Orientation}
                    AgentPort = {AgentManager.spawnBot Type init(BotId Port Maze X Y LowerOri)}
                    % Track the agent
                    BotInfo = bot('id':BotId 'type':Type 'name':Name 'x':X 'y':Y 'port':AgentPort 'alive':true)
                    UpdatedTracker = {AdjoinAt CurrentTracker BotId BotInfo}
                in
                    {SpawnBots Rest UpdatedTracker}
                end
            end
        end

        NewTracker = {SpawnBots Bots Tracker}

        Instance = {GameController state(
            'gui': GUI
            'maze': Maze
            'score': 0
            'tracker': NewTracker
        )}
    in
        % TODO: log the winning team name and the score then use {Application.exit 0}
        {Handler Stream Instance}
    end

    {StartGame}
end
