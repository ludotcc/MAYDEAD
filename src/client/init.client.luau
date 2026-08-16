print("[MAYDEAD] CLIENT BOOTSTRAP")

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local CONTROLLER_TIMEOUT = 10

--============================================================
-- ROBLOX CORE GUI
-- Désactive :
-- 1. Backpack / hotbar Roblox native
-- 2. Barre de santé Roblox native
--============================================================

local function disableNativeCoreGui()
	task.spawn(function()
		local disabled = false

		repeat
			disabled = pcall(function()
				StarterGui:SetCoreGuiEnabled(
					Enum.CoreGuiType.Backpack,
					false
				)

				StarterGui:SetCoreGuiEnabled(
					Enum.CoreGuiType.Health,
					false
				)
			end)

			if not disabled then
				task.wait(0.1)
			end
		until disabled

		print(
			"[MAYDEAD] Native Backpack and Health CoreGui disabled"
		)
	end)
end

--============================================================
-- MODULE SEARCH
--============================================================

local function findModule(container, moduleName)
	if not container then
		return nil
	end

	local candidates = {
		moduleName,
		moduleName .. ".module",
		moduleName .. ".luau",
		moduleName .. ".module.luau",
	}

	for _, candidateName in ipairs(candidates) do
		local module =
			container:FindFirstChild(candidateName)

		if module
			and module:IsA("ModuleScript")
		then
			return module
		end
	end

	return nil
end

--============================================================
-- CONTROLLER RESOLUTION
--============================================================

local function tryFindController(
	container,
	moduleName
)
	if not container then
		return nil
	end

	-- Cherche d'abord dans le dossier UI
	local uiFolder =
		container:FindFirstChild("UI")

	if uiFolder then
		local module =
			findModule(
				uiFolder,
				moduleName
			)

		if module then
			return module
		end
	end

	-- Puis directement dans le container
	return findModule(
		container,
		moduleName
	)
end

local function resolveController(moduleName)
	local deadline =
		os.clock() + CONTROLLER_TIMEOUT

	while os.clock() < deadline do
		local containers = {
			script,
			script.Parent,
			script.Parent
				and script.Parent.Parent,
		}

		for _, container in ipairs(containers) do
			local module =
				tryFindController(
					container,
					moduleName
				)

			if module then
				print(
					"[MAYDEAD] Found "
						.. moduleName
						.. " as ["
						.. module.Name
						.. "]"
				)

				local ok, controller =
					pcall(
						require,
						module
					)

				if not ok then
					warn(
						"[MAYDEAD] "
							.. module.Name
							.. " require ERROR: "
							.. tostring(controller)
					)

					return nil
				end

				if controller
					and typeof(controller.Start)
						== "function"
				then
					return controller
				end

				warn(
					"[MAYDEAD] "
						.. module.Name
						.. " does not expose Start()"
				)

				return nil
			end
		end

		task.wait(0.1)
	end

	warn(
		"[MAYDEAD] "
			.. moduleName
			.. " not found after "
			.. tostring(CONTROLLER_TIMEOUT)
			.. " seconds"
	)

	return nil
end

--============================================================
-- HUD STARTUP
--============================================================

local function startHUD()
	local mainMenuController = resolveController("MainMenuController")
	if mainMenuController then
		local ok, err = xpcall(function() mainMenuController:Start() end, debug.traceback)
		if not ok then warn("[MAYDEAD] MainMenuController ERROR: " .. tostring(err)) end
	else
		warn("[MAYDEAD] MainMenuController not found")
	end

	--========================================================
	-- TIME HUD
	--========================================================

	local timeController =
		resolveController(
			"TimeHUDController"
		)

	if timeController then
		local ok, err =
			xpcall(function()
				timeController:Start()
			end, debug.traceback)

		if not ok then
			warn(
				"[MAYDEAD] TimeHUD ERROR: "
					.. tostring(err)
			)
		end
	else
		warn(
			"[MAYDEAD] TimeHUDController not found"
		)
	end

	--========================================================
	-- SURVIVAL HUD
	--========================================================

	print(
		"[MAYDEAD] Loading SurvivalHUDController"
	)

	local survivalController =
		resolveController(
			"SurvivalHUDController"
		)

	if survivalController then
		print(
			"[MAYDEAD] SurvivalHUDController loaded"
		)

		print(
			"[MAYDEAD] Starting SurvivalHUDController"
		)

		local ok, err =
			xpcall(function()
				survivalController:Start()
			end, debug.traceback)

		if not ok then
			warn(
				"[MAYDEAD] SurvivalHUD Start ERROR: "
					.. tostring(err)
			)
		end
	else
		warn(
			"[MAYDEAD] SurvivalHUDController "
				.. "could not be started"
		)
	end

	local touchJumpController = resolveController("TouchJumpIntegrationController")
	if touchJumpController then
		local ok, err = xpcall(function() touchJumpController:Start() end, debug.traceback)
		if not ok then warn("[MAYDEAD] TouchJumpIntegrationController ERROR: " .. tostring(err)) end
	else
		warn("[MAYDEAD] TouchJumpIntegrationController not found")
	end

	local drinkController =
		resolveController(
			"DrinkController"
		)

	if drinkController then
		local ok, err = xpcall(function()
			drinkController:Start()
		end, debug.traceback)

		if not ok then
			warn(
				"[MAYDEAD] DrinkController ERROR: "
					.. tostring(err)
			)
		end
	else
		warn("[MAYDEAD] DrinkController not found")
	end

	--========================================================
	-- INVENTORY
	--========================================================

	local inventoryController =
		resolveController(
			"InventoryController"
		)

	if inventoryController then
		local ok, err =
			xpcall(function()
				inventoryController:Start()
			end, debug.traceback)

		if not ok then
			warn(
				"[MAYDEAD] InventoryController ERROR: "
					.. tostring(err)
			)
		end
	else
		warn(
			"[MAYDEAD] InventoryController not found"
		)
	end

	local rawMeatDropController = resolveController("RawMeatDropController")
	if rawMeatDropController then
		local ok, err = xpcall(function() rawMeatDropController:Start() end, debug.traceback)
		if not ok then warn("[MAYDEAD] RawMeatDropController ERROR: " .. tostring(err)) end
	else
		warn("[MAYDEAD] RawMeatDropController not found")
	end
	local cheetahTamingController = resolveController("CheetahTamingController")
	if cheetahTamingController then
		local ok, err = xpcall(function() cheetahTamingController:Start() end, debug.traceback)
		if not ok then warn("[MAYDEAD] CheetahTamingController ERROR: " .. tostring(err)) end
	end
	local cheetahCompanionController = resolveController("CheetahCompanionController")
	if cheetahCompanionController then
		local ok, err = xpcall(function() cheetahCompanionController:Start() end, debug.traceback)
		if not ok then warn("[MAYDEAD] CheetahCompanionController ERROR: " .. tostring(err)) end
	end

	local craftingController =
		resolveController(
			"CraftingController"
		)

	if craftingController then
		local ok, err = xpcall(function()
			craftingController:Start()
		end, debug.traceback)
		if not ok then
			warn("[MAYDEAD] CraftingController ERROR: " .. tostring(err))
		end
	else
		warn("[MAYDEAD] CraftingController not found")
	end

	local stationController =
		resolveController(
			"StationController"
		)

	if stationController then
		local ok, err = xpcall(function()
			stationController:Start()
		end, debug.traceback)
		if not ok then
			warn("[MAYDEAD] StationController ERROR: " .. tostring(err))
		end
	else
		warn("[MAYDEAD] StationController not found")
	end

	local factoryStatusController = resolveController("FactoryStatusController")
	if factoryStatusController then
		local ok, err = xpcall(function() factoryStatusController:Start() end, debug.traceback)
		if not ok then warn("[MAYDEAD] FactoryStatusController ERROR: " .. tostring(err)) end
	else
		warn("[MAYDEAD] FactoryStatusController not found")
	end

	local cropController = resolveController("CropController")
	if cropController then
		local ok, err = xpcall(function()
			cropController:Start()
		end, debug.traceback)
		if not ok then
			warn("[MAYDEAD] CropController ERROR: " .. tostring(err))
		end
	else
		warn("[MAYDEAD] CropController not found")
	end

	local placementController =
		resolveController(
			"PlacementController"
		)

	if placementController then
		local ok, err = xpcall(function()
			placementController:Start()
		end, debug.traceback)
		if not ok then
			warn("[MAYDEAD] PlacementController ERROR: " .. tostring(err))
		end
	else
		warn("[MAYDEAD] PlacementController not found")
	end

	local harvestController =
		resolveController(
			"HarvestController"
		)

	if harvestController then
		local ok, err = xpcall(function()
			harvestController:Start()
		end, debug.traceback)
		if not ok then
			warn("[MAYDEAD] HarvestController ERROR: " .. tostring(err))
		end
	else
		warn("[MAYDEAD] HarvestController not found")
	end

	local lootCardController = resolveController("LootCardController")
	if lootCardController then
		local ok, err = xpcall(function() lootCardController:Start() end, debug.traceback)
		if not ok then warn("[MAYDEAD] LootCardController ERROR: " .. tostring(err)) end
	else
		warn("[MAYDEAD] LootCardController not found")
	end

	local fishingController = resolveController("FishingController")
	if fishingController then
		local ok, err = xpcall(function()
			fishingController:Start()
		end, debug.traceback)
		if not ok then
			warn("[MAYDEAD] FishingController ERROR: " .. tostring(err))
		end
	else
		warn("[MAYDEAD] FishingController not found")
	end
end

--============================================================
-- BOOTSTRAP
--============================================================

disableNativeCoreGui()

if Players.LocalPlayer then
	task.defer(startHUD)
else
	Players:GetPropertyChangedSignal(
		"LocalPlayer"
	):Wait()

	task.defer(startHUD)
end
