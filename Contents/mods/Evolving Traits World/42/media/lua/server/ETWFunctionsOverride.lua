--require "ETWModOptions";
local ETWCommonFunctions;
local ETWCommonLogicChecks;
local ETWCombinedTraitChecks;

--if not isServer() then
	ETWCommonFunctions = require "ETWCommonFunctions";
    ETWCommonLogicChecks = require "ETWCommonLogicChecks";
    ETWCombinedTraitChecks = require "ETWCombinedTraitChecks";
--end

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld;

local modOptions;

---@return boolean
local notification = function() return modOptions:getOption("EnableNotifications"):getValue() end;
---@return boolean
local delayedNotification = function() return modOptions:getOption("EnableDelayedNotifications"):getValue() end;
---@return boolean
local debug = function() return modOptions:getOption("GatherDebug"):getValue() end;
---@return boolean
local detailedDebug = function() return modOptions:getOption("GatherDetailedDebug"):getValue() end;

local original_OnEat_Cigarettes = OnEat_Cigarettes;
---Overwriting OnEat_Cigarettes here to insert ETW logic catching player smoking
---@param food any
---@param character IsoGameCharacter
---@param percent number
function OnEat_Cigarettes(food, character, percent)
	if not isServer() then
		modOptions = PZAPI.ModOptions:getOptions("ETWModOptions");
		if detailedDebug() then print("ETW Logger | OnEat_Cigarettes(): detected smoking") end;
		local modData = character:getModData().EvolvingTraitsWorld;
		local smokerModData = modData.SmokeSystem; -- SmokingAddiction MinutesSinceLastSmoke
		local timeSinceLastSmoke = character:getTimeSinceLastSmoke() * 60;
		if detailedDebug() then print("ETW Logger | OnEat_Cigarettes(): timeSinceLastSmoke: " .. timeSinceLastSmoke .. ", modData.MinutesSinceLastSmoke: " .. smokerModData.MinutesSinceLastSmoke) end;
		local stress = character:getStats():getStress(); -- stress is 0-1, may be higher with stress from cigarettes
		local panic = character:getStats():getPanic(); -- 0-100
		local addictionGain = SBvars.SmokingAddictionMultiplier * (1 + stress) * (1 + panic / 100) * 1000 / (math.max(timeSinceLastSmoke, smokerModData.MinutesSinceLastSmoke) + 100);
		if SBvars.AffinitySystem and modData.StartingTraits.Smoker then
			addictionGain = addictionGain * SBvars.AffinitySystemGainMultiplier;
		end
		smokerModData.SmokingAddiction = math.min(SBvars.SmokerCounter * 2, smokerModData.SmokingAddiction + addictionGain);
		if debug() then print("ETW Logger | OnEat_Cigarettes(): addictionGain: " .. addictionGain .. ", modData.SmokingAddiction: " .. smokerModData.SmokingAddiction) end;
		smokerModData.MinutesSinceLastSmoke = 0;
	end
	original_OnEat_Cigarettes(food, character, percent);
end

local original_Recipe_OnCreate_RipClothing = Recipe.OnCreate.RipClothing;
---Overwriting Recipe.OnCreate.RipClothing() here to insert ETW logic catching player ripping clothing
---@param craftRecipeData 
---@param character IsoPlayer
function Recipe.OnCreate.RipClothing(craftRecipeData, character)
	if not isServer() then
		local modData = ETWCommonFunctions.getETWModData(character)
		if #modData.UniqueClothingRipped < SBvars.SewerUniqueClothesRipped and ETWCommonLogicChecks.SewerShouldExecute() then
			local items = craftRecipeData:getAllConsumedItems();
			local item = items:get(0)
			modOptions = PZAPI.ModOptions:getOptions("ETWModOptions");
			---@type DebugAndNotificationArgs
			local DebugAndNotificationArgs = {debug = debug(), detailedDebug = detailedDebug(), notification = notification(), delayedNotification = delayedNotification()};
			---@cast item Clothing
			if detailedDebug() then print("ETW Logger | Recipe.OnCreate.RipClothing() item: " .. item:getName()) end;
			ETWCombinedTraitChecks.addClothingToUniqueRippedClothingList(character, item, DebugAndNotificationArgs);
		end
	end
    original_Recipe_OnCreate_RipClothing(craftRecipeData, character);
end