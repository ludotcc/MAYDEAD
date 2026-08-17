local CheetahConfig = require(script.Parent.Parent.Config.CheetahConfig)
local SharkConfig = require(script.Parent.Parent.Config.SharkConfig)

return table.freeze({
	Bison = table.freeze({
		TemplateName = "Bison",
		MaxHealth = 100,
		AttackRange = 8,
		AttackCooldown = 0.65,
		CorpseLifetime = 4,
		RespawnTime = 300,
		AllowedTools = table.freeze({
			Axe = table.freeze({ItemId = "StoneAxe", Damage = 25, ImpactSoundName = "Wood"}),
			Pickaxe = table.freeze({ItemId = "StonePickaxe", Damage = 20, ImpactSoundName = "Stone"}),
		}),
		Drop = table.freeze({ItemId = "RawMeat", Amount = 6}),
	}),
	Cheetah = table.freeze({
		TemplateName = "Cheetah",
		MaxHealth = CheetahConfig.MAX_HEALTH,
		AttackRange = 8,
		AttackCooldown = 0.65,
		CorpseLifetime = CheetahConfig.CORPSE_LIFETIME,
		RespawnTime = CheetahConfig.RESPAWN_DELAY,
		AllowedTools = table.freeze({
			Axe = table.freeze({ItemId = "StoneAxe", Damage = 25, ImpactSoundName = "Wood"}),
			Pickaxe = table.freeze({ItemId = "StonePickaxe", Damage = 20, ImpactSoundName = "Stone"}),
		}),
		Drop = table.freeze({ItemId = "RawMeat", MinAmount = CheetahConfig.LOOT_MIN, MaxAmount = CheetahConfig.LOOT_MAX}),
	}),
	Shark = table.freeze({
		TemplateName = "Shark",
		MaxHealth = SharkConfig.MAX_HEALTH,
		AttackRange = 8,
		AttackCooldown = 0.65,
		CorpseLifetime = 0,
		RespawnTime = SharkConfig.RESPAWN_DELAY,
		NoLoot = true,
		AllowedTools = table.freeze({
			Axe = table.freeze({ItemId = "StoneAxe", Damage = 25, ImpactSoundName = "Wood"}),
			Pickaxe = table.freeze({ItemId = "StonePickaxe", Damage = 20, ImpactSoundName = "Stone"}),
		}),
	}),
})
