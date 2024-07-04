--[[
* Addons - Copyright (c) 2021 Ashita Development Team
* Contact: https://www.ashitaxi.com/
* Contact: https://discord.gg/Ashita
*
* This file is part of Ashita.
*
* Ashita is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Ashita is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with Ashita.  If not, see <https://www.gnu.org/licenses/>.
--]]

addon.author   = 'Almavivaconte (ported to Ashita v4 by Zal Das, updated by GetAwayCoxn)'
addon.name     = 'ticker'
addon.version  = '1.1'
addon.desc     = 'A simple text box to display when your next resting tick is going to happen'
addon.link	   = 'https://github.com/clanofartisans/ticker'

require ('common')
local settings = require('settings')
local fonts = require('fonts')
local display = {}
local osd = {}
local defaults = T{
	visible = true,
	font_family = 'Arial',
	font_height = 24,
	color = 0xFFFFFFFF,
	position_x = 500,
	position_y = 500,
	background = T{
		visible = true,
		color = 0xFF000000,
	}
}
local tickTime = 21
local _timer = 0
local lastHP = nil
local lastMP = nil


ashita.events.register('load', 'load_cb', function()
    osd.settings = settings.load(defaults)

	settings.register('settings', 'settings_update', function (s)
		if s then osd.settings = s end
		settings.save()
	end)

	display = fonts.new(osd.settings)
end)

ashita.events.register('unload', 'unload_cb', function()
    settings.save()

    if display then display:destroy() end
end)

ashita.events.register('d3d_present', 'present_cb', function()
	if display.position_x ~= osd.settings.position_x or display.position_y ~= osd.settings.position_y then
		osd.settings.position_x = display.position_x
		osd.settings.position_y = display.position_y
		settings.save()
	end
	local party = AshitaCore:GetMemoryManager():GetParty()
	local currentHP = party:GetMemberHP(0)
	local currentHPP = party:GetMemberHPPercent(0)
	local currentMP = party:GetMemberMP(0)
	local currentMPP = party:GetMemberMPPercent(0)
	local selfIndex = party:GetMemberTargetIndex(0)
	local me = GetEntity(selfIndex)
	local currentStatus = 0

	if not selfIndex or not currentHPP or not currentHP or not currentMPP or not currentMP or not me then return end

	currentStatus = me.Status
	display.visible = false

	if currentStatus == 33 then
		local buffs = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs()
		local regen = false
		for _, buff in pairs(buffs) do
			if buff == 42 or buff == 539 then
				regen = true
			end
		end
		display.visible = true
		if currentHPP == 100 and currentMPP == 100 or currentHPP == 100 and currentMP == 0 then
			display.text = "Ready!"
			tickTime = 21
		elseif (not regen and lastHP and currentHP > lastHP + 9) or (lastMP and currentMP > lastMP + 9) then
			_timer = os.time()
			lastHP = currentHP
			lastMP = currentMP
			tickTime = 10
			display.text = tostring(tickTime)
		elseif not lastHP or not lastMP then
			lastHP = currentHP
			lastMP = currentMP
		elseif os.time() >= _timer + 1 then
			_timer = os.time()
			if tickTime <= 0 then
				display.text = display.text .. "."
			else
				tickTime = tickTime - 1
				display.text = tostring(tickTime)
			end
		end
	else
		if lastHP ~= currentHP then
			lastHP = currentHP
		elseif lastMP ~= currentMP then
			lastMP = currentMP
		end
		tickTime = 21
	end
end)