local WeaponInfoTable = require(script.Parent.WeaponInfoTable)
local StyleInfoTable = {

	Fists = {
		Damage = 5,
		--[[StatusBuffs = {
			{	Type = whattypeofbuffsoitcanbeyourstatusbuffsorwhatever,
				Name = Nameofthebuffadded,
				Amount = howmuch of thebuff you want to give
			}
		},]]--
		ComboRefreshTime = 2,
		SwingSpeed = 1,
		DebounceTime = .25,
		StaminaUsage = 5,
		AttackAmount = 5,
		AnimSpeeds = {
			First = 1,
			Second = 1,
			Third = 1,
			Fourth = 1,
		},
		DamageType = "Regular",
		AnimationIDs = {
			Anim1 = "rbxassetid://117580018688309",
			Anim2 = "rbxassetid://86596754367463",
			Anim3 = "rbxassetid://117580018688309",
			Anim4 = "rbxassetid://104647042849224",
			Anim5 = "rbxassetid://90991571986289",
			Equip = "rbxassetid://123714366025675",
			Idle = "rbxassetid://123714366025675",
			Block = "rbxassetid://10138578669",
			Sprint = "rbxassetid://14597023355",
			BlockBroken = "rbxassetid://119531585337541"
		},
		StunAnimations = {
			Anim1 = "rbxassetid://10138560882",
			Anim2 = "rbxassetid://10138566166",
			Anim3 = "rbxassetid://10138570593",
			Anim4 = "rbxassetid://10138574938",
			Anim5 = "rbxassetid://92416263058843",
		},
		HitboxInfo = {
			["Right Arm"] = {
				HitboxSize = Vector3.new(1.5, 1.5, 1.5),
				HitboxPosition = Vector3.new(0, -0.5, 0),
				HitboxOrientation = Vector3.new(0, 0, 0),
			},
			["Left Arm"] = {
				HitboxSize = Vector3.new(1.5, 1.5, 1.5),
				HitboxPosition = Vector3.new(0, -0.5, 0),
				HitboxOrientation = Vector3.new(0, 0, 0),
			},
		},
		RagdollTime = 2,
		EffectName = "NoWeapon",
		BlockInteraction = "blockable",
		FrameHealthReduction = 10,
		BlockDamage = 7,
		Hits = 1,
		SecondarySkill = "HEAVY SWING",
		HitboxLocation = "Arms",
		EXPLOCATION = {
			"Buso",
			"FistExp",
			"OverallCombatExp"
		},
		StunTime = 1, 
		KnockbackForce = 50,
	}, 

	Kicks = {
		Damage = 5,
		--[[StatusBuffs = {
			{	Type = whattypeofbuffsoitcanbeyourstatusbuffsorwhatever,
				Name = Nameofthebuffadded,
				Amount = howmuch of thebuff you want to give
			}
		},]]--
		ComboRefreshTime = 2,
		SwingSpeed = 0.15,
		DebounceTime = 0,
		StaminaUsage = 0,
		AttackAmount = 5,
		AnimSpeeds = {
			First = 1,
			Second = 1,
			Third = 1,
			Fourth = 1,
		},
		DamageType = "Regular",
		AnimationIDs = {
			Anim1 = "idk",
			Anim2 = "idk",
			Anim3 = "idk",
			Anim4 = "idk",
			Anim5 = "idk",
			Equip = "idk",
			Idle = "idk",
			Block = "idk",
			BlockBroken = "rbxassetid://119531585337541",
		},
		StunAnimations = {
			Anim1 = "rbxassetid://10138560882",
			Anim2 = "rbxassetid://10138566166",
			Anim3 = "rbxassetid://10138570593",
			Anim4 = "rbxassetid://10138574938",
			Anim5 = "rbxassetid://92416263058843",
		},
		HitboxSize = Vector3.new(5,5,5),
		RagdollTime = 2,
		EffectName = "DefaultFist",
		BlockInteraction = "blockable",
		FrameHealthReduction = 10,
		Hits = 1,
		SecondarySkill = "HEAVY KICK",
		HitboxLocation = "Legs",
		EXPLOCATION = {
			"Buso",
			"KickExp",
			"OverallCombatExp"
		},
		StunTime = 1,
		KnockbackForce = 50,
	},
	
	Katana = {
		Damage = 7.5,
		--[[StatusBuffs = {
			{	Type = whattypeofbuffsoitcanbeyourstatusbuffsorwhatever,
				Name = Nameofthebuffadded,
				Amount = howmuch of thebuff you want to give
			}
		},]]--
		ComboRefreshTime = 2.5,
		SwingSpeed = 1,
		DebounceTime = 0,
		StaminaUsage = 0,
		AttackAmount = 5,
		AnimSpeeds = {
			First = 1,
			Second = 1,
			Third = 1,
			Fourth = 1,
		},
		DamageType = "Regular",
		AnimationIDs = {
			Anim1 = "rbxassetid://71564960699353",
			Anim2 = "rbxassetid://128419621185738",
			Anim3 = "rbxassetid://70447417875613",
			Anim4 = "rbxassetid://80564068278684",
			Anim5 = "rbxassetid://78607413698534",
			Equip = "rbxassetid://79305837020948",
			Idle = "rbxassetid://88583588918873",
			Block = "rbxassetid://106970598355944",
			Sprint = "rbxassetid://140308921469123",
			BlockBroken = "rbxassetid://119531585337541",
		},
		StunAnimations = {
			Anim1 = "rbxassetid://10138560882",
			Anim2 = "rbxassetid://10138566166",
			Anim3 = "rbxassetid://10138570593",
			Anim4 = "rbxassetid://10138574938",
			Anim5 = "rbxassetid://92416263058843",
		},
		HitboxSize = Vector3.new(5,5,5),
		RagdollTime = 2,
		EffectName = "DefaultFist",
		BlockInteraction = "blockable",
		FrameHealthReduction = 10,
		Hits = 1,
		SecondarySkill = "HEAVY KICK",
		EXPLOCATION = {
			"Buso",
			"SwordExp",
			"SlashingWeaponExp",
			"OverallCombatExp"
		},
		StunTime = 1, 
		KnockbackForce = 50,
	},
	
	Bisento = {
		Damage = 7.5,
		--[[StatusBuffs = {
			{	Type = whattypeofbuffsoitcanbeyourstatusbuffsorwhatever,
				Name = Nameofthebuffadded,
				Amount = howmuch of thebuff you want to give
			}
		},]]--
		ComboRefreshTime = 2.5,
		SwingSpeed = 1,
		DebounceTime = 0,
		StaminaUsage = 0,
		AttackAmount = 5,
		AnimSpeeds = {
			First = 1,
			Second = 1,
			Third = 1,
			Fourth = 1,
		},
		DamageType = "Regular",
		AnimationIDs = {
			Anim1 = "rbxassetid://95622628099950",
			Anim2 = "rbxassetid://98638004000748",
			Anim3 = "rbxassetid://133446842568688",
			Anim4 = "rbxassetid://89053715331430",
			Anim5 = "rbxassetid://111848512794361",
			Equip = "rbxassetid://79305837020948",
			Idle = "rbxassetid://94759810223767",
			Block = "rbxassetid://104711454759931",
			Sprint = "rbxassetid://119965015097745",
			BlockBroken = "rbxassetid://119531585337541",
		},
		StunAnimations = {
			Anim1 = "rbxassetid://117405777320837",
			Anim2 = "rbxassetid://126542934236871",
			Anim3 = "rbxassetid://117405777320837",
			Anim4 = "rbxassetid://104163277251373",
			Anim5 = "rbxassetid://92416263058843",
		},
		HitboxSize = Vector3.new(5,5,5),
		RagdollTime = 2,
		EffectName = "DefaultFist",
		BlockInteraction = "blockable",
		FrameHealthReduction = 10,
		Hits = 1,
		SecondarySkill = "HEAVY KICK",
		EXPLOCATION = {
			"Buso",
			"RangedWeaponExp",
			"SlashingWeaponExp",
			"OverallCombatExp"
		},
		StunTime = 1, 
		KnockbackForce = 50,
	},
}

return StyleInfoTable