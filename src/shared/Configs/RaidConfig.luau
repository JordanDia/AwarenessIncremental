return {
	RaidInterval = 1 * 10, -- 30 minutes between raids
	RaidDuration = 5 * 60, -- 5 minute raid duration
	WarningTime = 5, -- seconds before raid to show warning

	DemonCount = 1,
	DemonHealth = 100,
	DemonDamageToSpirit = 5,
	DemonAttackInterval = 2,

	SpiritHealth = 1000,

	AttackRange = 30, -- studs

	Moves = {
		{
			Name = "Move1",
			Damage = 1,
			Cooldown = 0.8,
			Keybind = Enum.KeyCode.One,
			Unlocked = true, -- always unlocked
		},
		{
			Name = "Move2",
			Damage = 25,
			Cooldown = 5,
			Keybind = Enum.KeyCode.Two,
			Unlocked = true, -- placeholder: unlock via progression later
		},
		{
			Name = "Move3",
			Damage = 50,
			Cooldown = 8,
			Keybind = Enum.KeyCode.Three,
			Unlocked = true,
		},
		{
			Name = "Move4",
			Damage = 100,
			Cooldown = 15,
			Keybind = Enum.KeyCode.Four,
			Unlocked = true,
		},
	},
}
