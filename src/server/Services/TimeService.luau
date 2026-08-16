local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local TimeConfig = require(SharedFolder:WaitForChild("Config"):WaitForChild("TimeConfig"))

local TimeService = {}

-- Age remains the legacy persisted source of truth for schema V1 worlds.
-- Player-facing years are derived from it without rewriting existing saves.
local STARTING_AGE = TimeConfig.LEGACY_AGE_OFFSET

local DAY_START_HOUR = 6
local NIGHT_START_HOUR = 18

local UPDATE_RATE = 0.1
local CYCLE_DURATION = TimeConfig.DAY_DURATION + TimeConfig.NIGHT_DURATION

local currentAge = STARTING_AGE
local running = false

local timeFolder = ReplicatedStorage:FindFirstChild("TimeState")

if not timeFolder then
	timeFolder = Instance.new("Folder")
	timeFolder.Name = "TimeState"
	timeFolder.Parent = ReplicatedStorage
end

local ageValue = timeFolder:FindFirstChild("Age")

if not ageValue then
	ageValue = Instance.new("IntValue")
	ageValue.Name = "Age"
	ageValue.Parent = timeFolder
end

local yearsOnIslandValue = timeFolder:FindFirstChild("YearsOnIsland")

if not yearsOnIslandValue then
	yearsOnIslandValue = Instance.new("IntValue")
	yearsOnIslandValue.Name = "YearsOnIsland"
	yearsOnIslandValue.Parent = timeFolder
end

local periodValue = timeFolder:FindFirstChild("Period")

if not periodValue then
	periodValue = Instance.new("StringValue")
	periodValue.Name = "Period"
	periodValue.Parent = timeFolder
end

local cycleProgressValue = timeFolder:FindFirstChild("CycleProgress")

if not cycleProgressValue then
	cycleProgressValue = Instance.new("NumberValue")
	cycleProgressValue.Name = "CycleProgress"
	cycleProgressValue.Parent = timeFolder
end

local function setAge(age: number)
	currentAge = age
	ageValue.Value = age
	yearsOnIslandValue.Value = age - TimeConfig.LEGACY_AGE_OFFSET
end

local function setPeriod(periodName: string)
	periodValue.Value = periodName
end

local function updateCycleProgress(progress: number)
	cycleProgressValue.Value = math.clamp(progress, 0, 1)
end

local function applyProgress(progress)
	local nightStart = TimeConfig.DAY_DURATION / CYCLE_DURATION
	if progress < nightStart then
		setPeriod("Day")
		Lighting.ClockTime = DAY_START_HOUR + (12 * (progress / nightStart))
	else
		setPeriod("Night")
		local alpha = (progress - nightStart) / (1 - nightStart)
		Lighting.ClockTime = (NIGHT_START_HOUR + (12 * alpha)) % 24
	end
	updateCycleProgress(progress)
end

function TimeService:GetAge(): number
	return currentAge
end

function TimeService:GetYearsOnIsland(): number
	return currentAge - TimeConfig.LEGACY_AGE_OFFSET
end

function TimeService:GetPeriod(): string
	return periodValue.Value
end

function TimeService:GetPersistentState()
	return {
		Age = currentAge,
		CycleProgress = cycleProgressValue.Value,
		CycleTimingVersion = TimeConfig.CYCLE_TIMING_VERSION,
	}
end

function TimeService:RestorePersistentState(state)
	if typeof(state) ~= "table" or typeof(state.Age) ~= "number" or state.Age < STARTING_AGE
		or state.Age ~= math.floor(state.Age) or typeof(state.CycleProgress) ~= "number"
		or state.CycleProgress < 0 or state.CycleProgress >= 1
	then
		return false
	end
	local progress = state.CycleProgress
	if state.CycleTimingVersion == nil then
		local legacyCycleDuration = TimeConfig.LEGACY_DAY_DURATION + TimeConfig.NIGHT_DURATION
		local legacyElapsed = progress * legacyCycleDuration
		if legacyElapsed < TimeConfig.LEGACY_DAY_DURATION then
			progress = legacyElapsed / CYCLE_DURATION
		else
			local elapsedNight = legacyElapsed - TimeConfig.LEGACY_DAY_DURATION
			progress = (TimeConfig.DAY_DURATION + elapsedNight) / CYCLE_DURATION
		end
	elseif state.CycleTimingVersion ~= TimeConfig.CYCLE_TIMING_VERSION then
		return false
	end
	setAge(state.Age)
	applyProgress(progress)
	return true
end

function TimeService:Start()
	if running then
		return
	end

	running = true

	setAge(STARTING_AGE)
	applyProgress(0)

	task.spawn(function()
		while running do
			local dt = task.wait(UPDATE_RATE)
			local progress = cycleProgressValue.Value + (dt / CYCLE_DURATION)
			if progress >= 1 then
				progress -= 1
				setAge(currentAge + 1)
			end
			applyProgress(progress)
		end
	end)
end

function TimeService:Stop()
	running = false
end

return TimeService
