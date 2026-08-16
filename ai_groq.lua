local http = minetest.request_http_api()

local function get_player_key(name)
    if verity.keys[name] then return verity.keys[name] end
    local player = minetest.get_player_by_name(name)
    if player then
        local k = player:get_meta():get_string("groq_api_key")
        if k ~= "" then return k end
    end
    return nil
end

function verity.get_fallback_text()
    return verity.fallback_quotes[math.random(#verity.fallback_quotes)]
end

function verity.trigger_ai_dialogue(player, trigger_text)
    local name = player:get_player_name()
    local api_key = get_player_key(name)

    -- Fallback handling
    if not api_key or not http then
        minetest.chat_send_player(name, "<Verity> " .. verity.get_fallback_text())
        return
    end

    -- Context Gathering
    local pos = vector.round(player:get_pos())
    local hp = player:get_hp()
    local item = player:get_wielded_item():get_name()
    local time = minetest.get_timeofday() * 24
    time = string.format("%.1f:00", time)

    -- Sanity System Prompt
    local system_prompt = "You are Verity, a cryptic psychological horror entity in Minetest. Keep replies under 15 words."
    if hp > 15 then
        system_prompt = system_prompt .. " Personality: Calm, enigmatic, subtly disturbing."
    elseif hp > 7 then
        system_prompt = system_prompt .. " Personality: Creepy, overly personal, knowing."
    else
        system_prompt = system_prompt .. " Personality: Hostile, chaotic, aggressive, broken."
    end

    local context_prompt = string.format(
        "World State: Depth Y=%d, Time=%s, Player HP=%d/20, Wielding item='%s'. Player said: '%s'",
        pos.y, time, hp, item, trigger_text
    )

    local payload = minetest.parse_json({
        model = "llama-3.1-8b-instant",
        messages = {
            { role = "system", content = system_prompt },
            { role = "user", content = context_prompt }
        },
        max_tokens = 35,
        temperature = 0.8
    })

    http.fetch({
        url = "https://api.groq.com/openai/v1/chat/completions",
        method = "POST",
        extra_headers = {
            "Content-Type: application/json",
            "Authorization: Bearer " .. api_key
        },
        data = payload,
        timeout = 4,
    }, function(res)
        if res.succeeded and res.code == 200 then
            local data = minetest.parse_json(res.data)
            if data and data.choices and data.choices[1] then
                local reply = data.choices[1].message.content
                minetest.chat_send_player(name, "<Verity> " .. reply)
                minetest.sound_play("verity_whisper", {to_player = name, gain = 0.7})
                return
            end
        end
        -- Fallback on API failure
        minetest.chat_send_player(name, "<Verity> " .. verity.get_fallback_text())
    end)
end
