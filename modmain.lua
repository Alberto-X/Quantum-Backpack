--[[
NOTES:
	- net variables can only be changed by host?, so can only use for host -> client communication ?
	- -- An illustrative example of how to use a global prefab post init, in this case, we're making a player prefab post init.
	  env.AddPlayerPostInit = function(fn)
		  env.AddPrefabPostInitAny( function(inst)
			  if inst and inst:HasTag("player") then fn(inst) end
		  end)
	  end
	- 

]]

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
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.BACKPACK_QUANTUM = "This could be useful..."
GLOBAL.STRINGS.CHARACTERS.WICKERBOTTOM.DESCRIBE.BACKPACK_QUANTUM = "Quantum mechanics is not my specialty, but I won't question it."
GLOBAL.STRINGS.CHARACTERS.WENDY.DESCRIBE.BACKPACK_QUANTUM = "Can it teleport my heart away?"
GLOBAL.STRINGS.CHARACTERS.WAXWELL.DESCRIBE.BACKPACK_QUANTUM = "Oh Charlie, what have you done..."

AddRecipe("backpack_quantum", {GLOBAL.Ingredient("cutgrass", 6), GLOBAL.Ingredient("twigs", 6), GLOBAL.Ingredient("nightmarefuel", 2)}, GLOBAL.RECIPETABS.MAGIC, GLOBAL.TECH.MAGIC_TWO, nil, nil, nil, 1, nil, "images/inventoryimages/backpack_quantum.xml", "backpack_quantum.tex")
TUNING.QUANTA = {}

local function OnCannotBeOpenedDirty(inst)
	print(">> _cannotbeopened is dirty.")
	inst.components.container.canbeopened = not inst.replica.container._cannotbeopened:value()
end

local function modContainerReplica(component)
	print("AddComponentPostInit: ", component)
	print("AddComponentPostInit: ", component.inst)
	if component.inst.prefab == "backpack_quantum" then
		component._opener = net_entity(inst.GUID, "container._opener", "container._openerdirty")
		print("running container_replica mod")
		if GLOBAL.TheWorld.ismastersim then
			component.inst:ListenForEvent("container._cannotbeopeneddirty", OnCannotBeOpenedDirty)    --only need to check _cannotbeopened on host, so can update container.canbeopened (used in RUMMAGE action)
		end
		
		local orig_SetOpener = component.SetOpener
		component.SetOpener = function(self, opener)
			if self.inst.prefab == "backpack_quantum" then
				if opener then
					self._opener:set(opener)
				end
			end
			orig_SetOpener(self, opener)
		end
	end
end
--AddComponentPostInit("container_replica", modContainerReplica)

function modContainer(component)
	local orig_IsOpen = component.IsOpen
	component.IsOpen = function(self)
		print(">> running modded IsOpen")
		if self.inst.prefab == "backpack_quantum" then
			for k, v in pairs(TUNING.QUANTA) do
				if v.components.container.opener ~= nil then
					return true
				end
			end
			return false
		else
			orig_IsOpen(self)
		end
	end
	
	local orig_IsOpenedBy = component.IsOpenedBy
	component.IsOpenedBy = function(self, guy)
		print(">> running modded IsOpenedBy")
		if self.inst.prefab == "backpack_quantum" then
			for k, v in pairs(TUNING.QUANTA) do
				if v.components.container.opener == guy then
					return true
				end
			end
			return false
		else
			orig_IsOpenedBy(self, guy)
		end
	end
	
	local orig_Open = component.Open
	component.Open = function(self, doer)
		print(">> running modded Open")
		if not self:IsOpen() then
			orig_Open(self, doer)
			if self:IsOpen() then
				self.canbeopened = false
			end
		end
	end
	
	local orig_Close = component.Close
	component.Close = function(self)
		print(">> running modded Close")
		orig_Close(self)
		if not self:IsOpen() then
			self.canbeopened = true
		end
	end
end
AddComponentPostInit("container", modContainer)

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