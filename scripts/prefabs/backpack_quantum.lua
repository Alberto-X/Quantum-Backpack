local assets =
{
    Asset("ANIM", "anim/backpack.zip"),
    Asset("ANIM", "anim/swap_backpack.zip"),
    Asset("ANIM", "anim/ui_backpack_2x4.zip"),
}

local function onequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("backpack", skin_build, "backpack", inst.GUID, "swap_backpack" )
        owner.AnimState:OverrideItemSkinSymbol("swap_body", skin_build, "swap_body", inst.GUID, "swap_backpack" )
    else
        owner.AnimState:OverrideSymbol("backpack", "swap_backpack", "backpack")
        owner.AnimState:OverrideSymbol("swap_body", "swap_backpack", "swap_body")
    end

    if inst.components.container ~= nil then
        inst.components.container:Open(owner)
    end
end

local function onunequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner.AnimState:ClearOverrideSymbol("backpack")
    if inst.components.container ~= nil then
        inst.components.container:Close(owner)
    end
end

local function onburnt(inst)
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
        inst.components.container:Close()
    end

    SpawnPrefab("ash").Transform:SetPosition(inst.Transform:GetWorldPosition())

    inst:Remove()
end

local function onignite(inst)
    if inst.components.container ~= nil then
        inst.components.container.canbeopened = false
    end
end

local function onextinguish(inst)
    if inst.components.container ~= nil then
        inst.components.container.canbeopened = true
    end
end

local function onopen(inst)	
	print("Updating backpack (onopen): ", inst.GUID)
	if TUNING.QUANTA[1] and inst ~= TUNING.QUANTA[1] then
		for k = 1, inst.components.container:GetNumSlots() do
			inst.components.container:RemoveItemBySlot(k)
			inst.components.container:GiveItem(TUNING.QUANTA[1].components.container:RemoveItemBySlot(k), k)
		end
	end
end
local function onclose(inst, doer)
	print("start onclose() fn")
	if TUNING.QUANTA[1] and inst ~= TUNING.QUANTA[1] then
		for k = 1, inst.components.container:GetNumSlots() do
			TUNING.QUANTA[1].components.container:RemoveItemBySlot(k)
			TUNING.QUANTA[1].components.container:GiveItem(inst.components.container:RemoveItemBySlot(k), k)
		end
	end
	
	--[[for k, backpack in pairs(TUNING.QUANTA) do
		if backpack ~= inst then
			print("Updating backpack: ", backpack.GUID)
			for k2, slot in pairs(inst.components.container.slots) do
				if slot == nil then
					--backpack.components.container:RemoveItemBySlot(k2)
				else
					backpack.components.container.slots[k2] = slot
				end
				--if slot then
				--	backpack.components.container.slots[k2] = slot
				--end
			end
		end
	end]]
end

local function OnCannotBeOpenedDirty(inst)
	print(">> _cannotbeopened is dirty.")
	inst.components.container.canbeopened = not inst.replica.container._cannotbeopened:value()
end

local function modContainerReplica(self)
	print("Entity replicated: ", self)
	print("Entity replicated: ", self.inst)
	if self.prefab == "backpack_quantum" then
		print("Quantum entity replicated: ", self.GUID)
		self.replica.container._opener = net_entity(self.GUID, "container._opener", "container._openerdirty")
		if GLOBAL.TheWorld.ismastersim then
			self:ListenForEvent("container._cannotbeopeneddirty", OnCannotBeOpenedDirty)    --only need to check _cannotbeopened on host, so can update container.canbeopened (used in RUMMAGE action)
		end
		
		local orig_SetOpener = self.replica.container.SetOpener
		self.replica.container.SetOpener = function(self, opener)
			if self.inst.prefab == "backpack_quantum" then
				if opener then
					self._opener:set(opener)
				end
			end
			orig_SetOpener(self, opener)
		end
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("backpack1")
    inst.AnimState:SetBuild("swap_backpack")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("backpack")

    inst.MiniMapEntity:SetIcon("backpack_quantum.png")

    inst.foleysound = "dontstarve/movement/foley/backpack"
	
	inst.OnEntityReplicated = modContainerReplica

    inst.entity:SetPristine()	
		
	table.insert(TUNING.QUANTA, inst)

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "backpack_quantum"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/backpack_quantum.xml"
    inst.components.inventoryitem.cangoincontainer = true

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("backpack_quantum")
	inst.components.container.onopenfn = onopen
	inst.components.container.onclosefn = onclose

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    inst.components.burnable:SetOnBurntFn(onburnt)
    inst.components.burnable:SetOnIgniteFn(onignite)
    inst.components.burnable:SetOnExtinguishFn(onextinguish)

    MakeHauntableLaunchAndDropFirstItem(inst)

    return inst
end

return Prefab("backpack_quantum", fn, assets)
