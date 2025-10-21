functor

import
    OS
export
    'init': Get_init_state
define 

    Directions = directions(
        1: 'WEST'
        2: 'EAST'
        3: 'NORTH'
        4: 'SOUTH'
    )

    fun {Get_init_state}
        X_head = {OS.rand} mod 15
        Y_head = {OS.rand} mod 15

        Head_dir = Directions.({OS.rand} mod 4 + 1) % randon starting direction

        X_tail
        Y_tail

        X_fruit = {OS.rand} mod 15
        Y_fruit = {OS.rand} mod 15

    in
        case Head_dir of 'EAST' then 
            if X_head == 0 then X_head = 1 end
            X_tail = X_head - 1
            Y_tail = Y_head
        [] 'WEST' then
            if X_head == 15 then X_head = 14 end
            X_tail = X_head + 1
            Y_tail = Y_head 
        [] 'SOUTH' then
            if Y_head == 0 then Y_head = 1 end
            X_tail = X_head
            Y_tail = Y_head - 1
        [] 'NORTH' then
            if Y_head == 15 then Y_head = 14 end
            X_tail = X_head
            Y_tail = Y_head + 1
        end
        
        state(
            'head_loc':[X_head Y_head]
            'tail_loc':[X_tail Y_tail]
            'fruit_loc':[X_fruit Y_fruit]
            'head_dir': Head_dir
            'tail_dir': Head_dir
            'body': nil
        )
    end
end