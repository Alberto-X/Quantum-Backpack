PrefabFiles = 
{
	"backpack_quantum",
}

Assets = 
{
	Asset( "IMAGE", "minimap/backpack_quantum.tex" ),
	Asset( "ATLAS", "minimap/backpack_quantum.xml" ),
	Asset( "IMAGE", "images/inventoryimages/backpack_quantum.tex" ),
	Asset( "ATLAS", "images/inventoryimages/backpack_quantum.xml" ),
}
AddMinimapAtlas("minimap/backpack_quantum.xml")

local TUNING = GLOBAL.TUNING

local printnote = "Quantum Backpack Mod: "

GLOBAL.STRINGS.NAMES.BACKPACK_QUANTUM = "Quantumly Entangled Backpack"
GLOBAL.STRINGS.RECIPE_DESC.BACKPACK_QUANTUM = "In dire need of something simple?"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.BACKPACK_QUANTUM = "This could be quite useful..."
GLOBAL.STRINGS.CHARACTERS.WICKERBOTTOM.DESCRIBE.BACKPACK_QUANTUM = "I believe it uses exotic matter with negative energy density to stabilize it."
GLOBAL.STRINGS.CHARACTERS.WENDY.DESCRIBE.BACKPACK_QUANTUM = "Can it teleport my heart away?"
GLOBAL.STRINGS.CHARACTERS.WAXWELL.DESCRIBE.BACKPACK_QUANTUM = "Is this a portable pocket dimension?"
GLOBAL.STRINGS.CHARACTERS.WATHGRITHR.DESCRIBE.BACKPACK_QUANTUM = "This must be Loki's."
GLOBAL.STRINGS.CHARACTERS.WX78.DESCRIBE.BACKPACK_QUANTUM = "UNNATURAL PHYSICS DETECTED"
GLOBAL.STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.STORE.QUANTUMINUSE = "Someone must be using the portal."
GLOBAL.STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.RUMMAGE.QUANTUMINUSE = "I hear rustling on the other side."
GLOBAL.STRINGS.CHARACTERS.WX78.ACTIONFAIL.RUMMAGE.QUANTUMINUSE = "ERROR: PORTAL IS ACTIVE"
GLOBAL.STRINGS.CHARACTERS.WICKERBOTTOM.ACTIONFAIL.RUMMAGE.QUANTUMINUSE = "Schrödinger's cat must be in there..."

AddRecipe("backpack_quantum", {GLOBAL.Ingredient("cutgrass", 6), GLOBAL.Ingredient("twigs", 6), GLOBAL.Ingredient("nightmarefuel", 2)}, GLOBAL.RECIPETABS.MAGIC, GLOBAL.TECH.MAGIC_TWO, nil, nil, nil, 1, nil, "images/inventoryimages/backpack_quantum.xml", "backpack_quantum.tex")
GLOBAL.QUANTA_BACKPACK = {}

GLOBAL.SAVE_BACKPACK = nil

GLOBAL.containerwithitems = function()
	--find the quantum container with items
	for k, v in pairs(GLOBAL.QUANTA_BACKPACK) do
		if not v.components.container:IsEmpty() then
			return v
		end
	end
end

GLOBAL.quantumtunnel = function(from, target)
	--print(printnote.."Tunneling from "..tostring(from).." to "..tostring(target))
	if from ~= nil and target ~= nil then
		for i, slot in pairs(from.components.container.slots) do
			--Loop through every item in 'from' and move them to 'target'
			target.components.container:GiveItem(from.components.container:RemoveItemBySlot(i), i)
		end
	end
end

local function shallowquantumtunnel(from, target)
	if from ~= nil and target ~= nil then
		for i, slot in pairs(from.components.container.slots) do
			target.components.container.slots[i] = from.components.container:GetItemInSlot(i)
		end
	end
end

local function clearshallowcopy(target)
	if target ~= nil then
		for i, slot in pairs(target.components.container.slots) do
			target.components.container.slots[i] = nil
		end
	end
end

GLOBAL.findcontainerindex = function(inst)
	for k, v in pairs(GLOBAL.QUANTA_BACKPACK) do
		if v.GUID == inst.GUID then
			return k
		end
	end
end

GLOBAL.findopencontainer = function()
	for k, v in pairs(GLOBAL.QUANTA_BACKPACK) do
		if v.components.container:IsOpen() then
			return v
		end
	end
end

GLOBAL.CanOpenQuantum = function()
	for k, v in pairs(GLOBAL.QUANTA_BACKPACK) do
		if v.components.container:IsOpen() then
			return false
		end
	end
	return true
end

GLOBAL.AreMultipleOpen = function()
	local openCount = 0
	for k, v in pairs(GLOBAL.QUANTA_BACKPACK) do
		if v.components.container:IsOpen() then
			openCount = openCount + 1
		end
	end
	return openCount > 1
end

local RUMMAGEFN = GLOBAL.ACTIONS.RUMMAGE.fn
GLOBAL.ACTIONS.RUMMAGE.fn = function(act)
	local targ = act.target or act.invobject
	if targ.prefab == "backpack_quantum" and not targ.components.container:IsOpen() and not GLOBAL.CanOpenQuantum() then
		return false, "QUANTUMINUSE"
	else
		return RUMMAGEFN(act)
	end
end

local STOREFN = GLOBAL.ACTIONS.STORE.fn
GLOBAL.ACTIONS.STORE.fn = function(act)
    local target = act.target
	if target.components.container ~= nil and act.invobject.components.inventoryitem ~= nil and act.doer.components.inventory ~= nil and target.prefab == "backpack_quantum" then
		if not GLOBAL.CanOpenQuantum() and not target.components.container:IsOpenedBy(act.doer) then
			return false, "QUANTUMINUSE"
		end		
		if GLOBAL.CanOpenQuantum() then --if all the backpacks are closed, then put the act.invobject in the SAVE_BACKPACK and handle the quantumtunnel elsewhere
			act.target = GLOBAL.SAVE_BACKPACK
		end
		return STOREFN(act) --or else(if a backpack is open), then do the normal storing action
	end
	return STOREFN(act)
end

local function SaveBackpackHandling(prefab) --for when the game loads
	local OldOnLoad = prefab.OnLoad ----------This section will find the original SAVE_BACKPACK
	prefab.OnLoad = function(inst, data)
		if OldOnLoad ~= nil then
			OldOnLoad()
		end
		if data ~= nil and data.hidden then
			print(printnote.."Loading existing save backpack: "..tostring(inst))
			if GLOBAL.SAVE_BACKPACK ~= nil then
				GLOBAL.SAVE_BACKPACK:Remove()
			end
			GLOBAL.SAVE_BACKPACK = inst
			GLOBAL.SAVE_BACKPACK:AddTag("hidden")
			GLOBAL.SAVE_BACKPACK:Hide()
		end
	end
	local OldOnSave = prefab.OnSave ----------This section will mark the original SAVE_BACKPACK so it can be found by OnLoad
	prefab.OnSave = function(inst, data)
		if OldOnSave ~= nil then
			OldOnSave()
		end
		if inst:HasTag("hidden") then
			print(printnote.."Saving existing save backpack: "..tostring(inst))
			data.hidden = true
		end
	end
end
AddPrefabPostInit("backpack", SaveBackpackHandling)

local function AllowRummage(prefab)
	if prefab.UseItemFromInvTile ~= nil then
		local OldUseItemFromInvTile = prefab.UseItemFromInvTile
		prefab.UseItemFromInvTile = function(inst, item)
			if item.prefab == "backpack_quantum" and inst._activeitem == nil and inst.GetEquippedItem(inst, GLOBAL.EQUIPSLOTS.BODY) == item then
				inst._parent.components.playercontroller:RemoteUseItemFromInvTile(GLOBAL.BufferedAction(inst._parent, nil, GLOBAL.ACTIONS.RUMMAGE, item), item)
			else
				OldUseItemFromInvTile(inst, item)
			end
		end
	end
end
AddPrefabPostInit("inventory_classified", AllowRummage)

local function HandleRummage(component)
	if component.UseItemFromInvTile ~= nil then
		local OldInvCompUseItemFromInvTile = component.UseItemFromInvTile
		component.UseItemFromInvTile = function(self, item, actioncode, mod_name)
			if item.prefab == "backpack_quantum" and actioncode == GLOBAL.ACTIONS.RUMMAGE.code then
				print(printnote.."Received: RPC.UseItemFromInvTile, RUMMAGE requested for a backpack.")
				self.inst.components.locomotor:PushAction(GLOBAL.BufferedAction(self.inst, nil, GLOBAL.ACTIONS.RUMMAGE, item, nil, nil, nil), true)
			else
				OldInvCompUseItemFromInvTile(self, item, actioncode, mod_name)
			end
		end
	end
end
AddComponentPostInit("inventory", HandleRummage)

local function QuantumSave(component)
	local OldOnSave = component.OnSave
	component.OnSave = function(self)
		local open = GLOBAL.findopencontainer()
		if self.inst:HasTag("hidden") and open ~= nil then
			--print(printnote.."Quantum saving...")
			--Temporarily copy contents of the open quantum backpack, save it, then undo copy
			shallowquantumtunnel(open, self.inst)
			local ret = OldOnSave(self)
			clearshallowcopy(self.inst)
			return ret
		elseif self.inst.prefab ~= "backpack_quantum" then	--Don't save contents of quantum backpacks
			return OldOnSave(self)
		end
	end
end
AddComponentPostInit("container", QuantumSave)

--------------------------------------------------------------------------
--[[ backpack_quantum ]]
--------------------------------------------------------------------------
local params = {}

params.backpack_quantum =
{
    widget =
    {
        slotpos = {},
        animbank = "ui_backpack_2x4",
        animbuild = "ui_backpack_2x4",
        pos = GLOBAL.Vector3(-5, -70, 0),
    },
    issidewidget = true,
    type = "pack",
}

for y = 0, 3 do
    table.insert(params.backpack_quantum.widget.slotpos, GLOBAL.Vector3(-162, -75 * y + 114, 0))
    table.insert(params.backpack_quantum.widget.slotpos, GLOBAL.Vector3(-162 + 75, -75 * y + 114, 0))
end

local containers = GLOBAL.require "containers"
containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, params.backpack_quantum.widget.slotpos ~= nil and #params.backpack_quantum.widget.slotpos or 0)
local old_widgetsetup = containers.widgetsetup
function containers.widgetsetup(container, prefab, data)
	local pref = prefab or container.inst.prefab
	if pref == "backpack_quantum" then
		local t = params[pref]
		if t ~= nil then
			for k, v in pairs(t) do
				container[k] = v
			end
			container:SetNumSlots(container.widget.slotpos ~= nil and #container.widget.slotpos or 0)
		end
	else
		return old_widgetsetup(container, prefab)
    end
end