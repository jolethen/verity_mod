function verity.spawn_static_particles(player)
    local pos = player:get_pos()
    minetest.add_particlespawner({
        amount = 30,
        time = 1,
        minpos = vector.add(pos, {x=-2, y=0, z=-2}),
        maxpos = vector.add(pos, {x=2, y=2, z=2}),
        minvel = {x=-0.2, y=-0.2, z=-0.2},
        maxvel = {x=0.2, y=0.2, z=0.2},
        texture = "default_obsidian.png",
        minsize = 0.5,
        maxsize = 1.5,
        glow = 1,
    })
end

function verity.trigger_fake_sounds(player)
    local ppos = player:get_pos()
    local dir = player:get_look_dir()
    -- Calculate position behind player
    local behind = vector.subtract(ppos, vector.multiply(dir, 2))
    
    local sounds = {"verity_footstep", "verity_chest"}
    local chosen = sounds[math.random(#sounds)]
    
    minetest.sound_play(chosen, {
        pos = behind,
        to_player = player:get_player_name(),
        gain = 0.8,
    })
end
