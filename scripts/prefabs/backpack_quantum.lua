local assets =
{
    Asset("ANIM", "anim/backpack.zip"),
    Asset("ANIM", "anim/swap_backpack.zip"),
    Asset("ANIM", "anim/ui_backpack_2x4.zip"),
}

local function entangle(inst)
	print(tostring(inst).." has been entangled(aka added to QUANTA_BACKPACK).")
	table.insert(QUANTA_BACKPACK, inst)
end

local function unentangle(inst)
	print(tostring(inst).." has been unentangled(aka removed to QUANTA_BACKPACK).")
	quantumtunnel(inst, SAVE_BACKPACK)
	table.remove(QUANTA_BACKPACK, findcontainerindex(inst))
end

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

	--check other entangled backpacks before opening
    if inst.components.container ~= nil and CanOpenQuantum() then
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

local function onopen(inst, data)
	local doer = data.doer
	print("onopen: "..tostring(inst))
	if AreMultipleOpen() then
		print("   Multiple Open - inst: "..tostring(inst))
		inst.components.container:Close() --Close will automatically send the stuff back to the SAVE_BACKPACK
		quantumtunnel(SAVE_BACKPACK, findopencontainer())
	else
		print("   Single Open - inst: "..tostring(inst))
		quantumtunnel(SAVE_BACKPACK, inst)
	end
end

local function onclose(inst)
	quantumtunnel(inst, SAVE_BACKPACK)
end

local function onremoveentity(inst)
	unentangle(inst)
end

local function onload(inst, data)
	--Only for clients: Need to open the backpack AFTER a client player has been spawned, so use DoTaskInTime
	inst:DoTaskInTime(0, function(inst)
		if inst.components.container:IsOpen() then
			print("Closing/opening quantum backpack (0s after loading it): "..tostring(inst))
			print("   After 0s, IsOpen: "..tostring(inst.components.container:IsOpen()))
			local opener = inst.components.container.opener
			inst.components.container:Close()
			inst.components.container:Open(opener)
		end
	end)
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
	inst:AddTag("quantum")

    inst.MiniMapEntity:SetIcon("backpack_quantum.png")

    inst.foleysound = "dontstarve/movement/foley/backpack"

    inst.entity:SetPristine()
	
	--entangle each backpack instance
	entangle(inst)

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
	
	inst.OnLoad = onload
	
	--set "on remove" function, which unentangles each backpack
	inst.OnRemoveEntity = onremoveentity
	
	if SAVE_BACKPACK == nil then
		SAVE_BACKPACK = SpawnPrefab("backpack")
		SAVE_BACKPACK:AddTag("hidden")
		SAVE_BACKPACK.Transform:SetPosition(850,0,850)
	end

    return inst
end

return Prefab("backpack_quantum", fn, assets)
