functor

import
    System
    GhOzt000Basic
    PacmOz000Basic
    SnakeAgent
export
    'spawnBot': SpawnBot
define

    % Spawn the agent and returns its port
    fun {SpawnBot BotName Init}
        % Init => init(Id GameControllerPort Maze X Y Orientation)
        case BotName of
            'ghOzt000Basic' then {GhOzt000Basic.getPort Init}
        []  'pacmOz000Basic' then {PacmOz000Basic.getPort Init}
        []  'snake' then {SnakeAgent.getPort Init}
        []  'snake2' then {SnakeAgent.getPort Init}
        else
            {System.show 'Unknown BotName'}
            false
        end
    end
end