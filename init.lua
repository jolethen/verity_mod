dofile(minetest.get_modpath("verity_mod") .. "/config.lua")
dofile(minetest.get_modpath("verity_mod") .. "/effects.lua")
dofile(minetest.get_modpath("verity_mod") .. "/ai_groq.lua")
dofile(minetest.get_modpath("verity_mod") .. "/gui.lua")
dofile(minetest.get_modpath("verity_mod") .. "/entity.lua")

-- The Strange Package Node
minetest.register_node("verity_mod:strange_package", {
    description = "Strange Package",
    tiles = {"verity_package.png"},
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

-- Chat Trigger Handler (Case-Insensitive Mention Trigger)
minetest.register_on_chat_message(function(name, message)
    local lower_msg = string.lower(message)
    
    if string.find(lower_msg, "verity") then
        local player = minetest.get_player_by_name(name)
        if player then
            -- Trigger async Groq call
            minetest.after(0.5, function()
                verity.trigger_ai_dialogue(player, message)
            end)
        end
    end
end)
