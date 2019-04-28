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
	quantumtunnel(inst, containerempty()) --move items to an empty container
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
    quantumtunnel(inst, containerempty()) --move items to an empty container
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
	quantumtunnel(containerwithitems(), inst)
end

local function onremoveentity(inst)
	unentangle(inst)
	inst.components.container:DropEverything()
	inst.components.container:Close()
	print("BACKPACK: onremoveentity")
	print("   inst: "..tostring(inst))
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
	
	inst.OnEntityReplicated = modContainerReplica

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

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    inst.components.burnable:SetOnBurntFn(onburnt)
    inst.components.burnable:SetOnIgniteFn(onignite)
    inst.components.burnable:SetOnExtinguishFn(onextinguish)

    MakeHauntableLaunchAndDropFirstItem(inst)
	
	--set "on remove" function, which unentangles each backpack
	inst.OnRemoveEntity = onremoveentity

    return inst
end

return Prefab("backpack_quantum", fn, assets)
