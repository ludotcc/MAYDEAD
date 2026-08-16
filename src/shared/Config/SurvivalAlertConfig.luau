return {
	WARNING_THRESHOLD = 35,
	CRITICAL_THRESHOLD = 20,
	WARNING_TRANSITION = 0.24,
	CRITICAL_PULSE_DURATION = 0.9,
	TOAST_FADE_DURATION = 0.2,
	TOAST_HOLD_DURATION = 1.4,
	TOAST_COOLDOWN = 8,
	PRIORITY = {"Health", "Thirst", "Hunger", "Energy"},
	COLORS = {
		Health = Color3.fromRGB(190, 67, 73),
		Hunger = Color3.fromRGB(190, 125, 67),
		Thirst = Color3.fromRGB(76, 167, 225),
		Energy = Color3.fromRGB(215, 166, 63),
	},
	LABELS = {
		Health = "SANTÉ",
		Hunger = "FAIM",
		Thirst = "SOIF",
		Energy = "ÉNERGIE",
	},
}
