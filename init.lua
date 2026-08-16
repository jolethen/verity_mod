-- Global Mod Table Initialization (MUST be at the very top)
verity = {
    keys = {}
}

-- Load Mod Components
dofile(minetest.get_modpath("verity_mod") .. "/config.lua")
dofile(minetest.get_modpath("verity_mod") .. "/effects.lua")
dofile(minetest.get_modpath("verity_mod") .. "/ai_groq.lua")
dofile(minetest.get_modpath("verity_mod") .. "/gui.lua")
dofile(minetest.get_modpath("verity_mod") .. "/entity.lua")

-- The Strange Package Node
minetest.register_node("verity_mod:strange_package", {
    description = "Strange Package",
    tiles = {"default_chest_top.png"}, -- Built-in texture fallback
    groups = {oddly_breakable_by_hand = 2},
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if not clicker or not clicker:is_player() then return end
        minetest.remove_node(pos)
        
        -- Spawn Verity near player
        local ppos = clicker:get_pos()
        local spawn_pos = vector.add(ppos, {x=4, y=1, z=4})
        local ent = minetest.add_entity(spawn_pos, "verity_mod:verity")
        
        if ent then
            local lua_ent = ent:get_luaentity()
            lua_ent.target_player = clicker:get_player_name()
        end

        minetest.chat_send_player(clicker:get_player_name(), "<Verity> You shouldn't have opened that...")
    end,
})

-- Direct Slash Command Trigger (/talk_verity <message>)
minetest.register_chatcommand("talk_verity", {
    params = "<message>",
    description = "Talk directly to Verity via Groq AI",
    func = function(name, param)
        if param == "" then
            return false, "Usage: /talk_verity <your message here>"
        end

        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found."
        end

        minetest.chat_send_player(name, "[Verity Debug] Command executed! Calling AI dialogue...")
        verity.trigger_ai_dialogue(player, param)
        return true
    end,
})

-- Passive Chat Listener (Triggers whenever 'verity' is mentioned)
minetest.register_on_chat_message(function(name, message)
    local lower_msg = string.lower(message)
    
    if string.find(lower_msg, "verity") then
        local player = minetest.get_player_by_name(name)
        if player then
            minetest.chat_send_player(name, "[Verity Debug] Chat listener caught 'verity' trigger!")
            minetest.after(0.2, function()
                verity.trigger_ai_dialogue(player, message)
            end)
        end
    end
end)
