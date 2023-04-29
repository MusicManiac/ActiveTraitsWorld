require "ETWModData";

local SBvars = SandboxVars.EvolvingTraitsWorld;

local notification = function() return EvolvingTraitsWorld.settings.EnableNotifications end
local debug = function() return EvolvingTraitsWorld.settings.GatherDebug end

local function onZombieKill(zombie)
	local player = getPlayer();
	if player:HasTrait("Bloodlust") and player:DistTo(zombie) <= 4 then
		local bodydamage = player:getBodyDamage();
		local stats = player:getStats();
		local stressFromCigarettes = stats:getStressFromCigarettes();
		local unhappiness = bodydamage:getUnhappynessLevel(); -- 0-100
		local stress = math.max(0, stats:getStress() - stressFromCigarettes); -- 0-1
		local panic = stats:getPanic(); -- 0-100
		bodydamage:setUnhappynessLevel(math.max(0, unhappiness - 4));
		stats:setStress(math.max(0, stress - 0.04));
		stats:setPanic(math.max(0, panic - 4));
		if debug() then print("ETW Logger: Bloodlust kill. Unhappiness:"..unhappiness.."->"..bodydamage:getUnhappynessLevel()..", stress: "..math.min(1, stress + stressFromCigarettes).."->"..stats:getStress()..", panic: "..panic.."->"..stats:getPanic()) end
	end
end

local function checkWeightLimit(player)
	local traits = {
		{"Metalstrongback", "StrongBack", 5},
		{"Metalstrongback2", "StrongBack", 5},
		{"Strongback", "StrongBack", 2},
		{"Strongback2", "StrongBack", 2},
		{"Metalstrongback", nil, 4},
		{"Metalstrongback2", nil, 4},
		{"Strongback", nil, 2},
		{"Strongback2", nil, 2},
		{"WeakBack", nil, -1},
		{nil, nil, 0},
	}

	local maxWeightBase = 8;
	local strength = player:getPerkLevel(Perks.Strength);

	if getActivatedMods():contains("ToadTraits") then
		if player:HasTrait("packmule") then maxWeightBase = math.floor(SandboxVars.MoreTraits.WeightPackMule + strength / 5) end
		if player:HasTrait("packmouse") then maxWeightBase = SandboxVars.MoreTraits.WeightPackMouse end
		if not player:HasTrait("packmule") and not player:HasTrait("packmouse") then maxWeightBase = SandboxVars.MoreTraits.WeightDefault end
		maxWeightBase = maxWeightBase + SandboxVars.MoreTraits.WeightGlobalMod;
		if debug() then print("ETW Logger: [ToadTraits present] Set maxWeightBase to "..maxWeightBase) end
	end

	for _, trait in ipairs(traits) do
		local trait1, trait2, maxWeight = unpack(trait)
		if (not trait1 or player:HasTrait(trait1)) and (not trait2 or player:HasTrait(trait2)) then
			if not maxWeight then maxWeight = 0 end
			maxWeightBase = maxWeightBase + maxWeight;
			if debug() then print("ETW Logger: [SOTO compatibility] Set maxWeightBase to "..tostring(maxWeightBase)) end
			break
		end
	end

	if player:HasTrait("Hoarder") then
		maxWeightBase = maxWeightBase + strength * SBvars.HoarderWeight;
		if debug() then print("ETW Logger: Set Hoarder maxWeightBase to "..maxWeightBase) end
	end

	player:setMaxWeightBase(maxWeightBase);
end

local function rainTraits(player, rainIntensity)
	local primaryItem = player:getPrimaryHandItem();
	local secondaryItem = player:getSecondaryHandItem();
	local rainProtection = (primaryItem and primaryItem:isProtectFromRainWhileEquipped()) or (secondaryItem and secondaryItem:isProtectFromRainWhileEquipped());
	local bodydamage = player:getBodyDamage();
	local stats = player:getStats();
	local stressFromCigarettes = stats:getStressFromCigarettes();
	if player:HasTrait("Pluviophobia") then
		local unhappinessIncrease = 0.1 * rainIntensity * (rainProtection and 0.5 or 1) * SBvars.PluviophobiaMultiplier;
		bodydamage:setUnhappynessLevel(bodydamage:getUnhappynessLevel() + unhappinessIncrease);
		if debug() then print("ETW Logger: Pluviophobia: unhappinessIncrease:"..unhappinessIncrease) end
		local boredomIncrease = 0.02 * rainIntensity * (rainProtection and 0.5 or 1) * SBvars.PluviophobiaMultiplier;
		stats:setBoredom(stats:getBoredom() + boredomIncrease);
		if debug() then print("ETW Logger: Pluviophobia: boredomIncrease:"..boredomIncrease) end
		local stressIncrease = 0.04 * rainIntensity * (rainProtection and 0.5 or 1) * SBvars.PluviophobiaMultiplier;
		stats:setStress(math.min(1, stats:getStress() - stressFromCigarettes + stressIncrease));
		if debug() then print("ETW Logger: Pluviophobia: stressIncrease:"..stressIncrease) end
	elseif player:HasTrait("Pluviophile") then
		local unhappinessDecrease = 0.1 * rainIntensity * (rainProtection and 0.5 or 1) * SBvars.PluviophileMultiplier;
		bodydamage:setUnhappynessLevel(bodydamage:getUnhappynessLevel() - unhappinessDecrease);
		if debug() then print("ETW Logger: Pluviophile: unhappinessDecrease:"..unhappinessDecrease) end
		local boredomDecrease = 0.02 * rainIntensity * (rainProtection and 0.5 or 1) * SBvars.PluviophileMultiplier;
		stats:setBoredom(stats:getBoredom() - boredomDecrease);
		if debug() then print("ETW Logger: Pluviophile: boredomDecrease:"..boredomDecrease) end
		local stressDecrease = 0.04 * rainIntensity * (rainProtection and 0.5 or 1) * SBvars.PluviophileMultiplier;
		stats:setStress(math.max(0, stats:getStress() - stressFromCigarettes - stressDecrease));
		if debug() then print("ETW Logger: Pluviophile: stressDecrease:"..stressDecrease) end
	end
end

local function fogTraits(player, fogIntensity)
	local bodydamage = player:getBodyDamage();
	local stats = player:getStats();
	local stressFromCigarettes = stats:getStressFromCigarettes();
	if player:HasTrait("Homichlophobia") then
		local panicIncrease = 4 * fogIntensity * SBvars.HomichlophobiaMultiplier;
		local resultingPanic = stats:getPanic() + panicIncrease;
		if resultingPanic <= 50 then
			stats:setPanic(resultingPanic);
			if debug() then print("ETW Logger: Homichlophobia: panicIncrease:"..panicIncrease) end
		end
		local stressIncrease = 0.04 * fogIntensity * SBvars.HomichlophobiaMultiplier;
		local resultingStress = math.min(1, stats:getStress() + stressIncrease);
		if resultingStress <= 0.5 then
			stats:setStress(math.min(1, resultingStress - stressFromCigarettes));
			if debug() then print("ETW Logger: Homichlophobia: stressIncrease:"..stressIncrease) end
		end
	elseif player:HasTrait("Homichlophile") then
		local panicDecrease = 4 * fogIntensity * SBvars.HomichlophileMultiplier;
		stats:setPanic(stats:getPanic() - panicDecrease);
		if debug() then print("ETW Logger: Homichlophile: panicDecrease:"..panicDecrease) end
		local stressDecrease = 0.04 * fogIntensity * SBvars.HomichlophileMultiplier;
		stats:setStress(math.max(0, stats:getStress() - stressFromCigarettes - stressDecrease));
		if debug() then print("ETW Logger: Homichlophile: stressDecrease:"..stressDecrease) end
	end
end

local function oneMinuteUpdate()
	local player = getPlayer();
	if false and not getActivatedMods():contains("SimpleOverhaulTraitsAndOccupations") and not getActivatedMods():contains("MoreSimpleTraitsVanilla") and not getActivatedMods():contains("MoreSimpleTraits") then
		-- pending SOTO/MST update first
		checkWeightLimit(player)
	end
	if not getActivatedMods():contains("EvolvingTraitsWorldDisableHoarder") then checkWeightLimit(player) end
end

local function initializeTraitsLogic(playerIndex, player)
	Events.OnZombieDead.Remove(onZombieKill);
	Events.OnZombieDead.Add(onZombieKill);
	Events.EveryOneMinute.Remove(oneMinuteUpdate);
	Events.EveryOneMinute.Add(oneMinuteUpdate);
end

local function clearEvents(character)
	Events.OnZombieDead.Remove(onZombieKill);
	Events.EveryOneMinute.Remove(oneMinuteUpdate);
end

Events.EveryHours.Remove(SOcheckWeight);

Events.OnCreatePlayer.Remove(initializeTraitsLogic);
Events.OnCreatePlayer.Add(initializeTraitsLogic);
Events.OnCharacterDeath.Add(clearEvents);