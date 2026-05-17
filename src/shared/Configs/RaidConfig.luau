return {
	RaidInterval = 15 * 60, -- 30 minutes between raids
	RaidDuration = 5 * 60, -- 5 minute raid duration
	WarningTime = 5, -- seconds before raid to show warning

	AttackRange = 30, -- studs
	FragmentReward = 5,
	SpiritHealth = 1000,

	-- Wave system
	TotalWaves = 4,
	WaveTransitionTime = 2, -- seconds between waves

	Waves = {
		[1] = {
			DemonCount = 2,
			DemonHealth = 100,
			DemonDamageToSpirit = 5,
			DemonAttackInterval = 2,
		},
		[2] = {
			DemonCount = 4,
			DemonHealth = 150,
			DemonDamageToSpirit = 8,
			DemonAttackInterval = 1.8,
		},
		[3] = {
			DemonCount = 6,
			DemonHealth = 200,
			DemonDamageToSpirit = 12,
			DemonAttackInterval = 1.5,
		},
		[4] = {
			IsBossWave = true,
			DemonCount = 0,
			BossHealth = 500,
			BossAttackInterval = 3,
			BossDamageToSpirit = 15,
		},
	},

	Moves = {
		{
			Name = "Energy Blast",
			Damage = 10,
			Cooldown = 0.3,
			Keybind = Enum.KeyCode.One,
			RequiredAwakeningLevel = 0,
		},
		{
			Name = "Crystal Blast",
			Damage = 60,
			Cooldown = 5,
			Keybind = Enum.KeyCode.Two,
			RequiredAwakeningLevel = 1,
			Sustained = true,
			Duration = 2,
		},
		{
			Name = "Astral Burst",
			Damage = 50,
			Cooldown = 8,
			Keybind = Enum.KeyCode.Three,
			RequiredAwakeningLevel = 3,
			AOE = true,
			AOERadius = 15,
		},
		{
			Name = "Summon",
			Damage = 0,
			Cooldown = 30,
			Keybind = Enum.KeyCode.Four,
			RequiredAwakeningLevel = 6,
			Summon = true,
			SummonDuration = 15,
		},
	},

	-- Spirit voicelines
	Voicelines = {
		"Please... help me...",
		"The darkness is closing in...",
		"I can feel them draining my energy...",
		"Don't let them take me!",
		"Your light gives me strength!",
		"Together we can overcome this!",
		"I believe in you!",
		"The shadows... they're everywhere...",
		"Stay strong, warriors!",
		"I can sense your power growing!",
	},
	VoicelineDuration = 3,
	VoicelineCooldown = 8,
}
