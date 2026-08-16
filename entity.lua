-- Fallback built-in textures from Minetest's 'default' mod:
-- Phase 1 (Observer): Sand (light/pale yellowish look)
-- Phase 2 (Companion): Cobblestone (grey/rough look)
-- Phase 3 (Aggressive): Obsidian (dark/corrupted look)
local phase_textures = {
    [1] = "default_sand.png",
    [2] = "default_stone.png",
    [3] = "default_dirt.png"
}

minetest.register_entity("verity_mod:verity", {
    initial_properties = {
        physical = false,
        collisionbox = {-0.35, -0.35, -0.35, 0.35, 0.35, 0.35},
        visual = "sprite",
        visual_size = {x=1.5, y=1.5},
        textures = {"default_sand.png"},
        glow = 3,
    },
    target_player = nil,
    phase = 1,
    threat_level = 0,
    timer = 0,

    on_activate = function(self, staticdata)
        self.object:set_armor_groups({immortal = 1})
    end,

    on_step = function(self, dtime)
        self.timer = self.timer + dtime
        if self.timer < 0.5 then return end
        self.timer = 0

        if not self.target_player then
            for _, p in ipairs(minetest.get_connected_players()) do
                self.target_player = p:get_player_name()
                break
            end
            return
        end

        local player = minetest.get_player_by_name(self.target_player)
        if not player then return end

        local ppos = player:get_pos()
        local epos = self.object:get_pos()
        local dist = vector.distance(epos, ppos)

        -- Phase Progression Logic based on distance and threat
        if self.threat_level > 50 then self.phase = 3
        elseif self.threat_level > 20 then self.phase = 2
        else self.phase = 1 end

        self.object:set_properties({textures = {phase_textures[self.phase]}})

        -- Check Line of Sight (Player looking at Verity?)
        local p_look = player:get_look_dir()
        local to_entity = vector.normalize(vector.subtract(epos, ppos))
        local dot = vector.dot(p_look, to_entity)
        local is_looking = dot > 0.6 and minetest.line_of_sight(ppos, epos)

        -- Movement & Vanish Logic
        if is_looking then
            if self.phase == 3 then
                -- Phase 3 Teleports on direct eye contact
                local offset = {x=math.random(-5,5), y=0, z=math.random(-5,5)}
                self.object:set_pos(vector.add(ppos, offset))
            else
                -- Freeze or vanish behind cover
                self.object:set_velocity({x=0, y=0, z=0})
            end
            self.threat_level = math.min(100, self.threat_level + 2)
        else
            -- Move closer while unobserved
            if dist > 3 then
                local dir = vector.normalize(vector.subtract(ppos, epos))
                self.object:set_pos(vector.add(epos, vector.multiply(dir, 0.8)))
            end
        end

        -- Near-Player Effects
        if dist < 8 then
            verity.spawn_static_particles(player)
            if math.random() < 0.2 then
                -- Calls fake footstep/chest sound function from effects.lua
                verity.trigger_fake_sounds(player)
            end
        end
    end
})
