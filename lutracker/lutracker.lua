addon.name      = "lutracker"
addon.author    = "GetAwayCoxn"
addon.version   = "1.1"
addon.desc      = "Tracks moat info for lu shang's rod"
addon.link      = "https://github.com/GetAwayCoxn/HorizonXI-Addons"

require("common")
local SETTINGS = require("settings")
local imgui = require("imgui")

local settings = T{}
local DEFAULT_SETTINGS = T{
    visible = {true},
    total = {0},
    price = {3000},
}
local header = { 1.0, 0.75, 0.25, 1.0 }
local window_size = { 310, 125 }
local lastKnownGil = nil
local saveCheck = false
local lastSaveCall = os.time()

ashita.events.register("load", "load_cb", function()
    settings = SETTINGS.load(DEFAULT_SETTINGS)

	SETTINGS.register("settings", "settings_update", function (s)
        if s then settings = s end
        SETTINGS.save()
    end)
end)

ashita.events.register("unload", "unload_cb", function()
    SETTINGS.save()
end)

ashita.events.register("d3d_present", "present_cb", function ()
    if saveCheck then
        if os.time() - lastSaveCall > 5 then
            SETTINGS.save()
            saveCheck = false
        end
    end
    if not settings.visible[1] then return end
    imgui.SetNextWindowSize(window_size)
    if imgui.Begin("Lu Tracker", settings.visible, ImGuiWindowFlags_NoDecoration) then
        imgui.TextColored(header, "Lu Shang Tracker")
        imgui.ShowHelp("Talking to Ufanne will update your fish count from the chatlog.")
        imgui.SameLine()
        imgui.Indent(280)
        if imgui.Button("X") then
            settings.visible[1] = not settings.visible[1]
        end
        imgui.Separator()
        imgui.Indent(-280)
        if imgui.InputInt("Price (stack)",settings.price,100,1000) then
            saveCheck = true
        end
        if imgui.InputInt("Total Traded",settings.total,1,100) then
            saveCheck = true
        end
        imgui.TextColored(header,"Fishies Left:")
        imgui.SameLine()
        imgui.Text(comma_value(10000-settings.total[1]))
        imgui.SameLine()
        imgui.TextColored(header,"  Gil ish:")
        imgui.SameLine()
        imgui.Text(comma_value(math.ceil((10000-settings.total[1])/12*settings.price[1])))
        local percentage = settings.total[1]/10000
        imgui.ProgressBar(percentage, true, "")
    end
    imgui.End()
end)

ashita.events.register("command", "command_cb", function (e)
	local args = e.command:args()
    if #args == 0 or (args[1] ~= "/lutracker" and args[1] ~= "/lut") then
        return
    end

    e.blocked = true

    if #args == 1 then
        settings.visible[1] = not settings.visible[1]
    end
end)

ashita.events.register("text_in", "text_in_callback1", function(e)
    if settings.total[1] >= 10000 then return end
    if e.message:contains("Obtained") and e.message:contains("gil") then
        local i,j = string.find(e.message,"%d+")
        if i and j then
            local count = string.sub(e.message,i,j)
            lastKnownGil = tonumber(count) / 10
        end
    elseif e.message:contains("Ufanne") and e.message:contains("collected") then
        local words = e.message:args()
        local count = tonumber(words[5])
        if count then
            settings.total[1] = count
            SETTINGS.save()
        end
    elseif (e.message:contains("Joulet") or e.message:contains("Gallijaux")) and e.message:contains("carp") then
        local i,j = string.find(e.message,"%d+")
        if i and j then
            local count = string.sub(e.message,i,j)
            settings.total[1] = tonumber(count)
            SETTINGS.save()
        end
    elseif (e.message:contains("Joulet") or e.message:contains("Gallijaux")) and (e.message:contains("a fine haul") or e.message:contains("Bring more")) then
        if lastKnownGil then
            settings.total[1] = settings.total[1] + lastKnownGil
            SETTINGS.save()
            lastKnownGil = nil
        end
    end
end)

function comma_value(n) --credit--http://richard.warburton.it
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end