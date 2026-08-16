local function show_verity_gui(name)
    local formspec = "size[6,4]" ..
        "label[0.5,0.5;Verity Groq API Key Setup]" ..
        "pwdfield[0.5,1.5;5,0.8;key_input;Enter Groq API Key (gsk_...)]" ..
        "button[0.5,2.6;2.3,0.8;save_key;Save Key]" ..
        "button[3.2,2.6;2.3,0.8;clear_key;Clear Key]"

    minetest.show_formspec(name, "verity_mod:gui", formspec)
end

minetest.register_chatcommand("verity", {
    params = "[key]",
    description = "Open Verity setup GUI or set Groq API key directly (/verity gsk_...)",
    func = function(name, param)
        if param == "" then
            show_verity_gui(name)
            return true
        end

        if not param:find("^gsk_") then
            return false, "Invalid Groq API key format! Keys must start with 'gsk_'."
        end

        verity.keys[name] = param
        local player = minetest.get_player_by_name(name)
        if player then
            player:get_meta():set_string("groq_api_key", param)
        end
        return true, "Groq API Key set successfully!"
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "verity_mod:gui" then return end
    local name = player:get_player_name()

    if fields.save_key then
        local key = fields.key_input
        if key and key:find("^gsk_") then
            verity.keys[name] = key
            player:get_meta():set_string("groq_api_key", key)
            minetest.chat_send_player(name, "[Verity] API key saved successfully!")
        else
            minetest.chat_send_player(name, "[Verity] Invalid key! Must start with 'gsk_'")
        end
    elseif fields.clear_key then
        verity.keys[name] = nil
        player:get_meta():set_string("groq_api_key", "")
        minetest.chat_send_player(name, "[Verity] API key cleared.")
    end
end)
