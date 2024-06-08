addon.name      = "Exp"
addon.author    = "GetAwayCoxn"
addon.version   = "1.0"
addon.desc      = "Shows exp and tnl's for all jobs"
addon.link      = "https://github.com/GetAwayCoxn/Ashita-v4-Addons"

require("common")
local imgui = require("imgui")
local SETTINGS = require("settings")

local settings = T{}
local defaults = T{
    visible = {true},
    data = {
        [1] = {["level"]=0,["expCurrent"]=0,["expNeeded"]=0},
        [2] = {["level"]=0,["expCurrent"]=0,["expNeeded"]=0},
        [3] = {["level"]=0,["expCurrent"]=0,["expNeeded"]=0},
        [4] = {["level"]=0,["expCurrent"]=0,["expNeeded"]=0},
        [5] = {["level"]=0,["expCurrent"]=0,["expNeeded"]=0},
        [6] = {["level"]=0,["expCurrent"]=0,["expNeeded"]=0},
        [7] = {["level"]=0,["expCurrent"]=0,["expNeeded"]=0},
        [8] = {["level"]=0,["expCurrent"]=0,["expNeeded"]=0},
        [9] = {["level"]=0,["expCurrent"]=0,["expNeeded"]=0},
        [10] = {["level"]=0,["expCurrent"]=0,["expNeeded"]=0},
        [11] = {["level"]=0,["expCurrent"]=0,["expNeeded"]=0},
        [12] = {["level"]=0,["expCurrent"]=0,["expNeeded"]=0},
        [13] = {["level"]=0,["expCurrent"]=0,["expNeeded"]=0},
        [14] = {["level"]=0,["expCurrent"]=0,["expNeeded"]=0},
        [15] = {["level"]=0,["expCurrent"]=0,["expNeeded"]=0},
        [16] = {["level"]=0,["expCurrent"]=0,["expNeeded"]=0},
        [17] = {["level"]=0,["expCurrent"]=0,["expNeeded"]=0},
        [18] = {["level"]=0,["expCurrent"]=0,["expNeeded"]=0},
    },
    expTotal = 0,
    limitPoints = 0,
    meritPoints = 0,
    meritPointsMax = 0,
    delay = 10,
}
local windowSize = { 495, 270 }
local header = { 1.0, 0.75, 0.25, 1.0 }
local lastUpdated = os.time()
local lastKnownMainJob = 0
local jobMap = {
    [1] = "WAR",
    [2] = "MNK",
    [3] = "WHM",
    [4] = "BLM",
    [5] = "RDM",
    [6] = "THF",
    [7] = "PLD",
    [8] = "DRK",
    [9] = "BST",
    [10] = "BRD",
    [11] = "RNG",
    [12] = "SAM",
    [13] = "NIN",
    [14] = "DRG",
    [15] = "SMN",
    [16] = "BLU",
    [17] = "COR",
    [18] = "PUP",
}
local expSpentMap = T{
    0,500,1250,2250,3500,5000,6750,8750,10950,13350,
    15950,18750,21750,24950,28350,31950,35750,39750,43950,48350,
    52950,57750,62750,67850,73050,78350,83750,89250,94850,100550,
    106350,112250,118250,124350,130550,136850,143250,149750,156350,
    163050,169850,176750,183750,190850,198050,205350,212750,220250,
    227850,235550,243350,251350,260550,270950,282550,295350,309350,
    324550,340950,358550,377350,397350,418850,441850,466350,492350,
    519850, 548850, 579350, 611350, 645350, 681350, 719350, 759350, 801350,
}
local DEBUG = false


ashita.events.register("load", "load_cb", function()
    settings = SETTINGS.load(defaults)

	SETTINGS.register("settings", "settings_update", function (s)
        if s then
            settings = s
        end
        SETTINGS.save()
    end)
end)


ashita.events.register("unload", "unload_cb", function()
    SETTINGS.save()
end)


ashita.events.register("d3d_present", "present_cb", function()
    local player = AshitaCore:GetMemoryManager():GetPlayer()
    if player:GetIsZoning() ~= 0 then return end
    if os.time() - lastUpdated > settings.delay or lastKnownMainJob ~= player:GetMainJob() then
        UpdateJob(player)
    end

    -- Do things
    local totalBarString = "All Jobs 75! "
    local limitMode = false
    for j=1,18 do
        if settings.data[j]["level"] < 75 then
            totalBarString = "All Jobs EXP: "
        else
            limitMode = true
        end
    end
    local totalPercentageString = string.format("(%.2f%%)", settings.expTotal * 100)
    if DEBUG or limitMode then
        windowSize[2] = 295
    else
        windowSize[2] = 270
    end

    -- Draw things
    if not settings.visible[1] then return end
    imgui.SetNextWindowSize(windowSize)
    if imgui.Begin("Exp", settings.visible, ImGuiWindowFlags_NoDecoration) then
        if DEBUG then
            if imgui.Button("Reload") then
                AshitaCore:GetChatManager():QueueCommand(1, "/addon reload exp")
            end
        else
            imgui.TextColored(header,"  Exp!")
            imgui.ShowHelp("Use /exp to hide/show this window")
            imgui.SameLine()
            imgui.Text("   ")
        end
        imgui.SameLine()
        imgui.ProgressBar(settings.expTotal, { 350, 20 }, totalBarString..totalPercentageString)
        imgui.SameLine()
        imgui.Indent(465)
        if imgui.Button("X") then
            settings.visible[1] = false
        end
        imgui.Unindent(465)
        if DEBUG or limitMode then
            imgui.TextColored(header, "Merits ("..string.format("%02i",settings.meritPoints).."/"..string.format("%02i",settings.meritPointsMax)..")")
            imgui.SameLine()
            imgui.ProgressBar(settings.limitPoints/10000, {350, 20}, "TNM: "..tostring(10000-settings.limitPoints)..string.format(" (%.2f%%)",settings.limitPoints/10000*100))
        end
        imgui.Separator()
        for j = 1, 18 do
            imgui.BeginChild(jobMap[j] .. "_Child", { 155, 35 }, false)
            imgui.TextColored(header, jobMap[j])
            imgui.SameLine()
            if settings.data[j]["Level"] == 0 then
                imgui.Text("Unknown")
            else
                imgui.Text(string.format("%02d", settings.data[j]["level"]))
                imgui.SameLine()
                imgui.TextColored(header, "Tnl:")
                imgui.SameLine()
                imgui.Text(comma_value(settings.data[j]["expNeeded"] - settings.data[j]["expCurrent"]))
            end
            if settings.data[j]["level"] > 0 then
                local totalPercentage = (expSpentMap[settings.data[j]["level"]] + settings.data[j]["expCurrent"]) /
                expSpentMap[75]
                if expSpentMap[75] - (expSpentMap[settings.data[j]["level"]] + settings.data[j]["expCurrent"]) == 1 then
                    totalPercentage = 1
                end
                imgui.ProgressBar(settings.data[j]["expCurrent"]/settings.data[j]["expNeeded"], { 152, 5 }, "")
                imgui.ProgressBar(totalPercentage, { 152, 5 }, "")
            end
            imgui.EndChild()
            if j % 3 ~= 0 then
                imgui.SameLine()
            end
        end
    end
    imgui.End()
end)


ashita.events.register("command", "command_cb", function (e)
	local args = e.command:args()
    if #args == 0 or args[1] ~= "/exp" then
        return
    end

    e.blocked = true

    if #args == 1 then
        settings.visible[1] = not settings.visible[1]
    elseif #args == 2 and args[2]:any("debug") then
        DEBUG = not DEBUG
    end
end)


function UpdateJob(player)
    local player = player or AshitaCore:GetMemoryManager():GetPlayer()
    if not player then return end

    local mainJob = player:GetMainJob()
    local mainJobLevel = player:GetJobLevel(mainJob)
    local expCurrent = player:GetExpCurrent()
    local expNeeded = player:GetExpNeeded()
    local limitBreaker = player:GetIsLimitBreaker()

    if not mainJob or mainJob == 0 or not mainJobLevel or mainJobLevel == 0 or not expCurrent or not expNeeded then return end

    local updated = false
    if settings.data[mainJob]["level"] ~= mainJobLevel then
        settings.data[mainJob]["level"] = mainJobLevel
        updated = true
    end
    if settings.data[mainJob]["expCurrent"] ~= expCurrent then
        settings.data[mainJob]["expCurrent"] = expCurrent
        updated = true
    end
    if settings.data[mainJob]["expNeeded"] ~= expNeeded then
        settings.data[mainJob]["expNeeded"] = expNeeded
        updated = true
    end

    if limitBreaker then
        settings.limitPoints = player:GetLimitPoints()
        settings.meritPoints = player:GetMeritPoints()
        settings.meritPointsMax = player:GetMeritPointsMax()
    end

    UpdateTotalPercentage()
    if updated then SETTINGS.save() end
    lastKnownMainJob = mainJob
    lastUpdated = os.time()
end

function UpdateTotalPercentage()
    local total = 0
    for j=1,18 do
        if settings.data[j]["level"] > 0 then
            total = total + expSpentMap[settings.data[j]["level"]]+settings.data[j]["expCurrent"]
        end
    end
    local percentage = total / (expSpentMap[75]*18)
    if expSpentMap[75]*18 - total == 18 then
        percentage = 1
    end
    settings.expTotal = percentage
end

function comma_value(n) --credit--http://richard.warburton.it
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end