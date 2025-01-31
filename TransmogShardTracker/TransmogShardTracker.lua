local ADDON_NAME, ADDON_TABLE = ...


local Locale = GetLocale()


local TOKENS_SHARDS_OF_ILLUSION = "Shards of Illusion|n|cffffffff%d/%d|r"
local TOKENS_SHARDS_OF_ILLUSION_TOOLTIP = "Click to update"
if Locale == "deDE" then
	TOKENS_SHARDS_OF_ILLUSION = "Splitter der Illusion|n|cffffffff%d/%d|r"
	TOKENS_SHARDS_OF_ILLUSION_TOOLTIP = "Zum Updaten klicken"
end


function TransmogShardTracker_OnLoad(self)
	self.text:SetFormattedText(TOKENS_SHARDS_OF_ILLUSION, 0,0)
	self.tooltip = TOKENS_SHARDS_OF_ILLUSION_TOOLTIP
end


function TransmogShardTracker_OnUpdate(self, elapsed)
	-- self.tooltip = TOKENS_SHARDS_OF_ILLUSION_TOOLTIP
	
	self.text:SetFormattedText(TOKENS_SHARDS_OF_ILLUSION, 0,0)
end


function TransmogShardTracker_OnClick(self)
	print("TransmogShardTracker_OnClick")
end

