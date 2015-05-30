require "Window"

local HarvestMe = {}

local MAX_HARVEST_DISTANCE = 200

local HARVEST_TYPE = "Harvest"
local HOUSING_PLANT_TYPE = "HousingPlant"

local FERTILE_GROUND_EN = "Fertile Ground"
local FERTILE_GROUND_DE = "Fruchtbarer Boden"
local FERTILE_GROUND_FR = "Lance de l'âme"

function HarvestMe:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.player = nil
    self.form = nil
    self.plates = {}
    self.units = {}
    self.target = nil

    return o
end

function HarvestMe:Init()
    Apollo.RegisterAddon(self)
end

function HarvestMe:OnLoad()
    self.form = XmlDoc.CreateFromFile("HarvestMe.xml")

    Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
    Apollo.RegisterEventHandler("ChangeWorld", "OnChangeWorld", self)

    Apollo.CreateTimer("HarvestRefresh", 0.1, true)
    Apollo.RegisterTimerHandler("HarvestRefresh", "OnTimerRefreshed", self)
end

function HarvestMe:OnUnitCreated(unit)
    local type = unit:GetType()
    local id = unit:GetId()
    local name = unit:GetName()

    local isHarvestType = type == HARVEST_TYPE or type == HOUSING_PLANT_TYPE
    local isFertileGround = name == FERTILE_GROUND_EN or name == FERTILE_GROUND_DE or name == FERTILE_GROUND_FR

    if isHarvestType and not isFertileGround then
        -- remember unit
        self.units[id] = unit

        -- if plate doesn't already exist add it
        if self.plates[id] == nil then
            self:AddPlate(id)
        end
    end
end

function HarvestMe:OnUnitDestroyed(unit)
    local id = unit:GetId()

    if self.plates[id] ~= nil then
        self:RemovePlate(id)
        self.units[id] = nil
    end
end

function HarvestMe:OnChangeWorld()
    self.player = nil

    self:ClearPlates()
end

function HarvestMe:OnTimerRefreshed()
    if self.player == nil then
        self.player = GameLib.GetPlayerUnit()
    end

    for id in pairs(self.plates) do
        self:UpdatePlate(id)
    end
end

function HarvestMe:AddPlate(id)
    local unit = self.units[id]
    local plate = Apollo.LoadForm(self.form, "HarvestingPlate", "InWorldHudStratum", self)

    plate:SetUnit(unit)

    local tradeskill = unit:GetHarvestRequiredTradeskillName()
    local tradeskillTier = unit:GetHarvestRequiredTradeskillTier()

    if unit:GetType() == HARVEST_TYPE and tradeskill ~= "Farmer" then
        tradeskill = tradeskill.." ("..tradeskillTier..")"
    elseif unit:GetType() == HOUSING_PLANT_TYPE then
        tradeskill = "Farmer"
    end

    local plateType = plate:FindChild("HarvestType")
    local plateName = plate:FindChild("HarvestName")

    plateType:SetText(tradeskill)
    plateName:SetText(unit:GetName())

    self.plates[id] = plate

    self:UpdatePlate(id)
end

function HarvestMe:UpdatePlate(id)
    -- update visibility
    local isVisible = self:ShouldBeVisible(id)
    self.plates[id]:FindChild("Container"):Show(isVisible)

    -- if is not harvestable paint type red
    if self.player ~= nil and not self.units[id]:CanBeHarvestedBy(self.player) then
        -- for some reasons housing plants are not marked as "Harvestable"
        if self.units[id]:GetType() ~= HOUSING_PLANT_TYPE then
            self:PaintTypePlate(id, "red")
        end
    end
end

function HarvestMe:RemovePlate(id)
    if self.plates[id] ~= nil then
        self.plates[id]:Destroy()
        self.plates[id] = nil
    end
end

function HarvestMe:ClearPlates()
    for id in pairs(self.plates) do
        self:RemovePlate(id)
        self.units[id] = nil
    end
end

function HarvestMe:ShouldBeVisible(id)
    local isOnScreen = self.plates[id]:IsOnScreen()
    local isOccluded = self.plates[id]:IsOccluded()
    local isNearPlayer = self:IsNearPlayer(id)

    return isOnScreen and not isOccluded and isNearPlayer
end

function HarvestMe:IsNearPlayer(id)
    if self.player == nil then
        return false
    end

    local player = self.player:GetPosition()
    local unit = self.units[id]:GetPosition()

    local distance = math.sqrt(math.pow(player.x - unit.x, 2) + math.pow(player.y - unit.y, 2) + math.pow(player.z - unit.z, 2))

    return distance <= MAX_HARVEST_DISTANCE
end

function HarvestMe:PaintTypePlate(id, color)
    self.plates[id]:FindChild("HarvestType"):SetTextColor(color)
end

local HarvestMeInst = HarvestMe:new()
HarvestMeInst:Init()
