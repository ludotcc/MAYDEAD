local MetallurgyConfig = require(script.Parent:WaitForChild("MetallurgyConfig"))

local metalMining = MetallurgyConfig.Mining

return {
	HARVEST_RANGE = 8,
	HARVEST_COOLDOWN = 0.65,
	HAND_ANIMATION_ID = "",
	FEEDBACK_TWEEN_DURATION = 0.16,
	IMPACT_SOUND_VOLUME = 0.42,

	Resources = {
		Tree_Test = {
			MaxHealth = 100,
			RespawnTime = 60,
			CanHarvestByHand = true,
			HandDamage = 10,
			HandHarvestAmount = 2,
			Tools = {Axe = {ItemId = "StoneAxe", Damage = 25}},
			LootItemId = "Wood",
			LootQuantity = 8,
			ImpactSoundName = "Wood",
		},
		Stone_Test = {
			MaxHealth = 100,
			RespawnTime = 75,
			CanHarvestByHand = true,
			HandDamage = 10,
			HandHarvestAmount = 2,
			Tools = {Pickaxe = {ItemId = "StonePickaxe", Damage = 25}},
			LootItemId = "Stone",
			LootQuantity = 6,
			ImpactSoundName = "Stone",
		},
		MetalRock_Test = {
			MaxHealth = metalMining.MetalRock_Test.MaxHealth,
			RespawnTime = metalMining.MetalRock_Test.RespawnTime,
			CanHarvestByHand = false,
			Tools = {Pickaxe = {ItemId = "StonePickaxe", Damage = 25}},
			LootItemId = metalMining.MetalRock_Test.LootItemId,
			LootQuantityMin = metalMining.MetalRock_Test.DropMin,
			LootQuantityMax = metalMining.MetalRock_Test.DropMax,
			ImpactSoundName = "Metal",
		},
		CuivreRock = {
			MaxHealth = metalMining.CuivreRock.MaxHealth,
			RespawnTime = metalMining.CuivreRock.RespawnTime,
			CanHarvestByHand = false,
			Tools = {Pickaxe = {ItemId = "StonePickaxe", Damage = 25}},
			LootItemId = metalMining.CuivreRock.LootItemId,
			LootQuantityMin = metalMining.CuivreRock.DropMin,
			LootQuantityMax = metalMining.CuivreRock.DropMax,
			ImpactSoundName = "Metal",
		},
		OrRock = {
			MaxHealth = metalMining.OrRock.MaxHealth,
			RespawnTime = metalMining.OrRock.RespawnTime,
			CanHarvestByHand = false,
			Tools = {Pickaxe = {ItemId = "StonePickaxe", Damage = 25}},
			LootItemId = metalMining.OrRock.LootItemId,
			LootQuantityMin = metalMining.OrRock.DropMin,
			LootQuantityMax = metalMining.OrRock.DropMax,
			ImpactSoundName = "Metal",
		},
		Crystal_Test = {
			MaxHealth = 150,
			RespawnTime = 180,
			CanHarvestByHand = false,
			Tools = {Pickaxe = {ItemId = "StonePickaxe", Damage = 25}},
			LootItemId = "Crystal",
			LootQuantity = 3,
			ImpactSoundName = "Crystal",
		},
	},

	ImpactSoundIds = {
		Wood = "",
		Stone = "",
		Metal = "",
		Crystal = "",
	},
}
