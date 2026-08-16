return {
	Mining = {
		CuivreRock = {
			MaxHealth = 150,
			RespawnTime = 105,
			LootItemId = "CopperOre",
			DropMin = 3,
			DropMax = 5,
		},
		MetalRock_Test = {
			MaxHealth = 200,
			RespawnTime = 120,
			LootItemId = "RawMetal",
			DropMin = 2,
			DropMax = 4,
		},
		OrRock = {
			MaxHealth = 300,
			RespawnTime = 180,
			LootItemId = "GoldOre",
			DropMin = 1,
			DropMax = 3,
		},
	},

	Smelt = {
		InputSlots = 4,
		FuelSlots = 4,
		OutputSlots = 4,
		FuelDefinitions = {
			Wood = {
				BurnSeconds = 45,
			},
		},
		Recipes = {
			Copper = {
				InputItem = "CopperOre",
				InputAmount = 3,
				OutputItem = "CopperIngot",
				OutputAmount = 1,
				Duration = 18,
				StatusText = "FONTE DU CUIVRE",
			},
			Metal = {
				InputItem = "RawMetal",
				InputAmount = 4,
				OutputItem = "MetalIngot",
				OutputAmount = 1,
				Duration = 24,
				StatusText = "FONTE DU MÉTAL",
			},
			Gold = {
				InputItem = "GoldOre",
				InputAmount = 3,
				OutputItem = "GoldIngot",
				OutputAmount = 1,
				Duration = 36,
				StatusText = "FONTE DE L'OR",
			},
		},
		RecipeOrder = {"Copper", "Metal", "Gold"},
	},
}
