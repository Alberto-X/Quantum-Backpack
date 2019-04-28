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

GLOBAL.STRINGS.NAMES.BACKPACK_QUANTUM = "Quantumly Entangled Backpack"
GLOBAL.STRINGS.RECIPE_DESC.BACKPACK_QUANTUM = "In dire need of something simple?"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.BACKPACK_QUANTUM = "This could be quite useful..."
GLOBAL.STRINGS.CHARACTERS.WICKERBOTTOM.DESCRIBE.BACKPACK_QUANTUM = "Quantum mechanics is not my specialty, but I won't question it."
GLOBAL.STRINGS.CHARACTERS.WENDY.DESCRIBE.BACKPACK_QUANTUM = "Can it teleport my heart away?"
GLOBAL.STRINGS.CHARACTERS.WAXWELL.DESCRIBE.BACKPACK_QUANTUM = "Oh Charlie, what have you done..."

AddRecipe("backpack_quantum", {GLOBAL.Ingredient("cutgrass", 6), GLOBAL.Ingredient("twigs", 6), GLOBAL.Ingredient("nightmarefuel", 2)}, GLOBAL.RECIPETABS.MAGIC, GLOBAL.TECH.MAGIC_TWO, nil, nil, nil, 1, nil, "images/inventoryimages/backpack_quantum.xml", "backpack_quantum.tex")
GLOBAL.QUANTA_BACKPACK = {}

GLOBAL.containerwithitems = function()
	--find the quantum container with items
	for k, v in pairs(GLOBAL.QUANTA_BACKPACK) do
		if not v.components.container:IsEmpty() then
			return v
		end
	end
end

GLOBAL.containerempty = function()
	--find an empty quantum container
	for k, v in pairs(GLOBAL.QUANTA_BACKPACK) do
		if v.components.container:IsEmpty() then
			return v
		end
	end
end

GLOBAL.quantumtunnel = function(from, target)
	if from ~= nil and target ~= nil then
		for i, slot in pairs(from.components.container.slots) do
			--This will loop through every item in the chest with the items and move them to the called one
			target.components.container:GiveItem(from.components.container:RemoveItemBySlot(i), i)
		end
	end
end

GlOBAL.findcontainerindex = function(inst)
	for k, v in pairs(GLOBAL.QUANTA_BACKPACK) do
		if v.GUID == inst.GUID then
			return k
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

local RUMMAGEFN = GLOBAL.ACTIONS.RUMMAGE.fn

GLOBAL.ACTIONS.RUMMAGE.fn = function(act)
	local targ = act.target or act.invobject
	if targ.prefab == "backpack_quantum" and not targ.components.container:IsOpen() and not CanOpenQuantum() then
		return false, "INUSE"
	else
		return RUMMAGEFN(act)
	end
end

local function AllowRummage(prefab)
	if prefab.UseItemFromInvTile ~= nil then
		local OldUseItemFromInvTile = prefab.UseItemFromInvTile
		prefab.UseItemFromInvTile = function(inst, item)
			if item.prefab == "backpack_quantum" and inst._activeitem == nil and inst.GetEquippedItem(inst, EQUIPSLOTS.BODY) == item then
				inst._parent.components.playercontroller:RemoteUseItemFromInvTile(BufferedAction(self.inst, nil, ACTIONS.RUMMAGE, item), item)
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
			if item.prefab == "backpack_quantum" and actioncode == ACTIONS.RUMMAGE.code then
				print("Received: RPC.UseItemFromInvTile, RUMMAGE requested for a backpack.")
				self.inst.components.locomotor:PushAction(BufferedAction(self.inst, nil, ACTIONS.RUMMAGE, item, nil, nil, nil), true)
			else
				OldInvCompUseItemFromInvTile(self, item, actioncode, mod_name)
			end
		end
	end
end

AddComponentPostInit("inventory", HandleRummage)

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