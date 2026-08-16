-- Fetch HTTP handle immediately on mod initialization
local http = minetest.request_http_api()

local function get_player_key(name)
    -- 1. Check in-memory table
    if verity.keys and verity.keys[name] and verity.keys[name] ~= "" then
        return verity.keys[name]
    end

    -- 2. Fallback to player metadata
    local player = minetest.get_player_by_name(name)
    if player then
        local k = player:get_meta():get_string("groq_api_key")
        if k and k ~= "" then
            verity.keys[name] = k -- Sync to memory table
            return k
        end
    end
    return nil
end

function verity.get_fallback_text()
    if not verity.fallback_quotes or #verity.fallback_quotes == 0 then
        return "I am watching you."
    end
    return verity.fallback_quotes[math.random(#verity.fallback_quotes)]
end

function verity.trigger_ai_dialogue(player, trigger_text)
    local name = player:get_player_name()

    -- Debug Check 1: Ensure HTTP Handle is initialized
    if not http then
        minetest.chat_send_player(name, "[Verity Debug] CRITICAL: HTTP API handle is NIL!")
        minetest.chat_send_player(name, "[Verity Debug] Ensure 'secure.http_mods = verity_mod' is in minetest.conf AND restart the client.")
        minetest.chat_send_player(name, "<Verity> " .. verity.get_fallback_text())
        return
    end

    -- Debug Check 2: Retrieve API Key
    local api_key = get_player_key(name)
    if not api_key then
        minetest.chat_send_player(name, "[Verity Debug] FAIL: No API key found for player '" .. name .. "'. Use /verity <gsk_...>")
        minetest.chat_send_player(name, "<Verity> " .. verity.get_fallback_text())
        return
    end

    minetest.chat_send_player(name, "[Verity Debug] Key verified (" .. string.sub(api_key, 1, 7) .. "...). Dispatching HTTP request to Groq...")

    -- Context Gathering
    local pos = vector.round(player:get_pos())
    local hp = player:get_hp()
    local item = player:get_wielded_item():get_name()
    if item == "" then item = "Empty Hand" end
    local raw_time = minetest.get_timeofday() or 0.5
    local time_str = string.format("%.1f:00", raw_time * 24)

    -- Dynamic System Prompt (Sanity System)
    local system_prompt = "You are Verity, a cryptic psychological horror entity in Minetest. Keep replies strictly under 15 words."
    if hp > 15 then
        system_prompt = system_prompt .. " Personality: Calm, enigmatic, subtly disturbing."
    elseif hp > 7 then
        system_prompt = system_prompt .. " Personality: Creepy, overly personal, knowing."
    else
        system_prompt = system_prompt .. " Personality: Hostile, chaotic, aggressive, broken."
    end

    local context_prompt = string.format(
        "World Context: Depth Y=%d, Time=%s, Player HP=%d/20, Holding='%s'. Player said: '%s'",
        pos.y, time_str, hp, item, trigger_text
    )

    -- Build Payload
    local payload_table = {
        model = "llama-3.1-8b-instant",
        messages = {
            { role = "system", content = system_prompt },
            { role = "user", content = context_prompt }
        },
        max_tokens = 35,
        temperature = 0.8
    }

    http.fetch({
        url = "https://api.groq.com/openai/v1/chat/completions",
        method = "POST",
        extra_headers = {
            "Content-Type: application/json",
            "Authorization: Bearer " .. api_key
        },
        data = minetest.write_json(payload_table),
        timeout = 5,
    }, function(res)
        if res.succeeded and res.code == 200 then
            local data = minetest.parse_json(res.data)
            if data and data.choices and data.choices[1] and data.choices[1].message then
                local reply = data.choices[1].message.content
                minetest.chat_send_player(name, "[Verity Debug] Groq API Success (200 OK)!")
                minetest.chat_send_player(name, "<Verity> " .. reply)
                return
            end
        end

        -- Detailed Error Logging if fetch fails or returns bad status code
        minetest.chat_send_player(name, string.format(
            "[Verity Debug] API Request Failed! Code: %s | Raw Error: %s",
            tostring(res.code),
            tostring(res.data or "Timeout / Socket closed")
        ))
        minetest.chat_send_player(name, "<Verity> " .. verity.get_fallback_text())
    end)
end
