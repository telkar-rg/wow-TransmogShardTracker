local ADDON_NAME, ADDON_TABLE = ...


TransmogShardTrackerCharDB = TransmogShardTrackerCharDB or {}
TransmogShardTrackerCharDB["Shards_current"] = TransmogShardTrackerCharDB["Shards_current"] or 0
TransmogShardTrackerCharDB["Shards_maximum"] = TransmogShardTrackerCharDB["Shards_maximum"] or 0



local Locale = GetLocale()
local FIRST_ENTERING_WORLD = 1
local timeout = 0
local timeout_duration = 2
local PlayerName = "Unknown"

-- forward declaration
local db
local suppressMSG
local func_query_start


local TOKENS_SHARDS_OF_ILLUSION = "Shards of Illusion|n|cffffffff%d/%d|r"
local TOKENS_SHARDS_OF_ILLUSION_TOOLTIP = "Click to update"
local TOKENS_SHARDS_MSG_QUERY = "^You have (%d+) of (%d+) Shards of Illusion in total"
local TOKENS_SHARDS_MSG_BUY_TRANSMOG = "^(%d+) Shards of Illusion and %d+g %d+s %d+c were removed."
local TOKENS_SHARDS_MSG_GAINED = "^You receive (%d+) Shards of Illusion"
if Locale == "deDE" then
	TOKENS_SHARDS_OF_ILLUSION = "Splitter der Illusion|n|cffffffff%d/%d|r"
	TOKENS_SHARDS_OF_ILLUSION_TOOLTIP = "Zum Updaten klicken"
	TOKENS_SHARDS_MSG_QUERY = "^Ihr habt insgesamt (%d+) von (%d+) Splitter der Illusion"
	TOKENS_SHARDS_MSG_BUY_TRANSMOG = "^Es wurden (%d+) Splitter der Illusion und %d+g %d+s %d+k abgezogen."
	TOKENS_SHARDS_MSG_GAINED = "^Ihr erhaltet (%d+) Splitter der Illusion"
end


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
	self.text:SetFormattedText(TOKENS_SHARDS_OF_ILLUSION, TransmogShardTrackerCharDB["Shards_current"], TransmogShardTrackerCharDB["Shards_maximum"])
	self.tooltip = TOKENS_SHARDS_OF_ILLUSION_TOOLTIP
	
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
end


function TransmogShardTracker_OnUpdate(self, elapsed)
	-- self.tooltip = TOKENS_SHARDS_OF_ILLUSION_TOOLTIP
	
	self.text:SetFormattedText(TOKENS_SHARDS_OF_ILLUSION, TransmogShardTrackerCharDB["Shards_current"], TransmogShardTrackerCharDB["Shards_maximum"])
end


function TransmogShardTracker_OnClick(self)
	-- print("TransmogShardTracker_OnClick")
	func_query_start()
end


function TransmogShardTracker_OnEvent(self, event, ...)
	-- print("TransmogShardTracker_OnEvent", event, ...)
	
	if ( event == "PLAYER_ENTERING_WORLD") then
		if FIRST_ENTERING_WORLD then
			FIRST_ENTERING_WORLD = nil
			
			db = TransmogShardTrackerCharDB
			PlayerName = UnitName("player")
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
			TransmogShardTrackerCharDB["Shards_current"] = shards_current
			TransmogShardTrackerCharDB["Shards_maximum"] = shards_maximum
			return
		end
		
		local shards_changed = strmatch(select(1, ...), TOKENS_SHARDS_MSG_BUY_TRANSMOG)
		if shards_changed then
			TransmogShardTrackerCharDB["Shards_current"] = TransmogShardTrackerCharDB["Shards_current"] - shards_changed
			return
		end
		
		local shards_changed = strmatch(select(1, ...), TOKENS_SHARDS_MSG_GAINED)
		if shards_changed then
			TransmogShardTrackerCharDB["Shards_current"] = TransmogShardTrackerCharDB["Shards_current"] + shards_changed
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


