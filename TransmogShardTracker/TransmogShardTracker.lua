local ADDON_NAME, ADDON_TABLE = ...


-- TransmogShardTrackerCharDB = TransmogShardTrackerCharDB or {}
-- TransmogShardTrackerCharDB["Shards_current"] = TransmogShardTrackerCharDB["Shards_current"] or 0
-- TransmogShardTrackerCharDB["Shards_maximum"] = TransmogShardTrackerCharDB["Shards_maximum"] or 0
TransmogShardTrackerDB = TransmogShardTrackerDB or {}
-- TransmogShardTrackerDB.CLASS = TransmogShardTrackerDB.CLASS or {}
-- TransmogShardTrackerDB.SHARDS = TransmogShardTrackerDB.SHARDS or {}
-- TransmogShardTrackerDB.SHARDS.CUR = TransmogShardTrackerDB.SHARDS.CUR or 0
-- TransmogShardTrackerDB.SHARDS.MAX = TransmogShardTrackerDB.SHARDS.MAX or 0
local db = TransmogShardTrackerDB

local Locale = GetLocale()
local FIRST_ENTERING_WORLD = 1
local timeout = 0
local timeout_duration = 2
local PlayerName = "Unknown"
local tooltip_lines = {}
local tooltip_lines2 = {}

-- forward declaration
-- local db
local suppressMSG
local func_query_start
local changed_shards


local TOKENS_SHARDS_OF_ILLUSION = "Shards of Illusion"
local TOKENS_SHARDS_OF_ILLUSION_FORMAT = "Shards of Illusion|n|cffffffff%d/%d|r"
local TOKENS_SHARDS_OF_ILLUSION_TOOLTIP = "Click to update"
local TOKENS_SHARDS_MSG_QUERY = "^You have (%d+) of (%d+) Shards of Illusion in total"
local TOKENS_SHARDS_MSG_BUY_TRANSMOG = "^(%d+) Shards of Illusion and %d+g %d+s %d+c were removed."
local TOKENS_SHARDS_MSG_GAINED = "^You receive (%d+) Shards of Illusion"
if Locale == "deDE" then
	TOKENS_SHARDS_OF_ILLUSION = "Splitter der Illusion"
	TOKENS_SHARDS_OF_ILLUSION_FORMAT = "Splitter der Illusion|n|cffffffff%d/%d|r"
	TOKENS_SHARDS_OF_ILLUSION_TOOLTIP = "Zum Updaten klicken"
	TOKENS_SHARDS_MSG_QUERY = "^Ihr habt insgesamt (%d+) von (%d+) Splitter der Illusion"
	TOKENS_SHARDS_MSG_BUY_TRANSMOG = "^Es wurden (%d+) Splitter der Illusion und %d+g %d+s %d+k abgezogen."
	TOKENS_SHARDS_MSG_GAINED = "^Ihr erhaltet (%d+) Splitter der Illusion"
end

local ColorCode = {
	p05 = "|cff40c040", 	-- EASY_DIFFICULTY_COLOR
	p10 = "|cffffff00", 	-- FAIR_DIFFICULTY_COLOR
	p11 = "|cffff8040", 	-- DIFFICULT_DIFFICULTY_COLOR
	p20 = "|cffff2020", 	-- IMPOSSIBLE_DIFFICULTY_COLOR
}

local colorStr = {	
	HUNTER = "ffabd473",
	WARRIOR = "ffc79c6e",
	PALADIN = "fff58cba",
	MAGE = "ff3fc7eb",
	PRIEST = "ffffffff",
	WARLOCK = "ff8788ee",
	DEATHKNIGHT = "ffc41f3b",
	DRUID = "ffff7d0a",
	SHAMAN = "ff0070de",
	ROGUE = "fffff569",
}



local ORIG_ChatFrame_MessageEventHandler = ChatFrame_MessageEventHandler;
function ChatFrame_MessageEventHandler(self, event, ...)
	-- suppress chat msg when we are looking for our transmog msg
	if (event == "CHAT_MSG_SYSTEM") and suppressMSG then
		-- print(...)
		if strfind(select(1, ...), TOKENS_SHARDS_MSG_QUERY) then
			suppressMSG = nil
			timeout = 0
		else
			ORIG_ChatFrame_MessageEventHandler(self, event, ...)
		end
	else
		ORIG_ChatFrame_MessageEventHandler(self, event, ...)
	end
	
	if suppressMSG and (timeout < GetTime()) then
		suppressMSG = nil
	end
end


function TransmogShardTracker_OnLoad(self)
	self.text:SetFormattedText(TOKENS_SHARDS_OF_ILLUSION_FORMAT, 0, 0)
	self.tooltip = TOKENS_SHARDS_OF_ILLUSION_TOOLTIP
	
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
end


function TransmogShardTracker_OnUpdate(self, elapsed)
	self.text:SetFormattedText(TOKENS_SHARDS_OF_ILLUSION_FORMAT, TransmogShardTrackerDB[PlayerName][1], TransmogShardTrackerDB[PlayerName][2])
	
	-- self.tooltip = TOKENS_SHARDS_OF_ILLUSION_TOOLTIP
end


function TransmogShardTracker_OnEnter(self)
	
	GameTooltip:ClearLines()
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 5, 40);
	
	GameTooltip:SetText("|cfff2e699" ..TOKENS_SHARDS_OF_ILLUSION .. "|r")
	GameTooltipTexture1:SetTexture("Interface\\Icons\\Inv_enchant_shardgleamingsmall")
	GameTooltip:AddLine(" ")
	
	if changed_shards then
		changed_shards = nil
		wipe(tooltip_lines)
		wipe(tooltip_lines2)
		
		for n,entry in pairs(TransmogShardTrackerDB) do
			if entry[1] > 0 then 	-- only show chars with shards (ignores low lvl bank chars)
				local txt = format("|c%s%s|r", colorStr[entry.CLASS], n)
				tinsert(tooltip_lines, {entry[1], entry[2], txt})
			end
		end
		table.sort(tooltip_lines, 
			function(a,b)
				if a[1] == b[1] then
					return a[3] > b[3]
				else
					return a[1] > b[1]
				end
			end )
		
		for _,entry in pairs(tooltip_lines) do
			local p = entry[1] / entry[2]
			local txt = format("%d/%d", entry[1], entry[2])
			
			if p < 0.4545 then
				txt = ColorCode.p05 .. txt .. "|r"
			elseif p < 0.9090 then
				txt = ColorCode.p10 .. txt .. "|r"
			elseif p < 0.977 then
				txt = ColorCode.p11 .. txt .. "|r"
			else
				txt = ColorCode.p20 .. txt .. "|r"
			end
			
			tinsert(tooltip_lines2, { entry[3], txt } )
		end
	end
	
	for _,entry in pairs(tooltip_lines2) do
		GameTooltip:AddDoubleLine(entry[1], entry[2])
	end
	
	
	GameTooltip:Show()
	
	
end


function TransmogShardTracker_OnClick(self)
	-- print("TransmogShardTracker_OnClick")
	SendChatMessage(".t s", "WHISPER", nil, PlayerName)
end


function TransmogShardTracker_OnEvent(self, event, ...)
	-- print("TransmogShardTracker_OnEvent", event, ...)
	
	if ( event == "PLAYER_ENTERING_WORLD") then
		if FIRST_ENTERING_WORLD then
			FIRST_ENTERING_WORLD = nil
			
			PlayerName = UnitName("player")
			TransmogShardTrackerDB[PlayerName] = TransmogShardTrackerDB[PlayerName] or {}
			
			TransmogShardTrackerDB[PlayerName].CLASS = select(2, UnitClass("player"))
			TransmogShardTrackerDB[PlayerName][1] = TransmogShardTrackerDB[PlayerName][1] or 0
			TransmogShardTrackerDB[PlayerName][2] = TransmogShardTrackerDB[PlayerName][2] or 0
			
			self:RegisterEvent("CHAT_MSG_SYSTEM");
			self:UnregisterEvent("PLAYER_ENTERING_WORLD");
			func_query_start()
			return
		end
		
	elseif ( event == "CHAT_MSG_SYSTEM") then
		-- print("TransmogShardTracker_OnEvent", event, ...)
		local shards_current, shards_maximum = strmatch(select(1, ...), TOKENS_SHARDS_MSG_QUERY)
		if shards_current then
			-- print(format("Detected %d/%d", shards_current, shards_maximum))
			TransmogShardTrackerDB[PlayerName][1] = tonumber(shards_current) or 0
			TransmogShardTrackerDB[PlayerName][2] = tonumber(shards_maximum) or 0
			changed_shards = 1
			return
		end
		
		local shards_changed = strmatch(select(1, ...), TOKENS_SHARDS_MSG_BUY_TRANSMOG)
		if shards_changed then
			TransmogShardTrackerDB[PlayerName][1] = TransmogShardTrackerDB[PlayerName][1] - tonumber(shards_changed)
			changed_shards = 1
			return
		end
		
		local shards_changed = strmatch(select(1, ...), TOKENS_SHARDS_MSG_GAINED)
		if shards_changed then
			TransmogShardTrackerDB[PlayerName][1] = TransmogShardTrackerDB[PlayerName][1] + tonumber(shards_changed)
			changed_shards = 1
			return
		end
	end
end

function func_query_start()
	-- print("func_query_start")
	timeout = GetTime() + timeout_duration
	suppressMSG = 1
	SendChatMessage(".t s", "WHISPER", nil, PlayerName)
end

-- public query function of shard status
function TransmogShardTracker_Query(charName)
	if TransmogShardTrackerDB[charName] or not charName then
		return TransmogShardTrackerDB[charName or PlayerName][1], TransmogShardTrackerDB[charName or PlayerName][2]
	else
		return
	end
end
