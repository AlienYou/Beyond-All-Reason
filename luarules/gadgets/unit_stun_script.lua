
function gadget:GetInfo()
  return {
    name      = "Stun Script",
    desc      = "makes unit stun status known to unit scripts",
    author    = "Floris",
    date      = "April 2020",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true
  }
end

if not gadgetHandler:IsSyncedCode() then
	return false
end

local cannotParalyze = {}
for udid, ud in pairs(UnitDefs) do
    if ud.customParams and ud.customParams.paralyzemultiplier == 0 then
        cannotParalyze[udid] = true
    end
end

local spGetUnitIsStunned = Spring.GetUnitIsStunned
local spSetUnitCOBValue = Spring.SetUnitCOBValue

local isUnitStunned = {}
local hasSetStunned = {}
hasSetStunned[UnitDefNames['armsam'].id] = true

function gadget:GameFrame(n)
    if n % 30 == 2 then
        for i, unitID in pairs(Spring.GetAllUnits()) do
            if isUnitStunned[unitID] ~= nil and isUnitStunned[unitID] ~= spGetUnitIsStunned(unitID) then
                isUnitStunned[unitID] = spGetUnitIsStunned(unitID)
                spSetUnitCOBValue(unitID, COB.CRASHING, spGetUnitIsStunned(unitID) and 1 or 0)
                Spring.Echo('SetStunned  '..unitID..'  '..(spGetUnitIsStunned(unitID) and 1 or 0))
            end
        end
    end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
    if hasSetStunned[unitDefID] then
        isUnitStunned[unitID] = false
    end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if isUnitStunned[unitDefID] then
        isUnitStunned[unitID] = nil
	end
end
