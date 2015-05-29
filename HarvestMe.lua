require "Window"

local HarvestMe = {} 

function HarvestMe:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    return o
end

function HarvestMe:Init()
	local dependencies = {}
	
    Apollo.RegisterAddon(self, false, "", dependencies)
end

function HarvestMe:OnLoad()
end

local HarvestMeInst = HarvestMe:new()
HarvestMeInst:Init()
