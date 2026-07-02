local WeaponInfoTable = {

	DefaultFistWrap = {
		DamageModifier = 1.2,
		--[[StatusBuffs = {
			{	Type = whattypeofbuffsoitcanbeyourstatusbuffsorwhatever,
				Name = Nameofthebuffadded,
				Amount = howmuch of thebuff you want to give
			}
		},]]--
		ComboRefreshTimeModifier = 1,
		SwingSpeedModifier = 1.1,
		DebounceTimeModifier = 1.25,
		StaminaUsageModifier = 1.15,
		AnimSpeedsModifier = {
			First = 1,
			Second = 1,
			Third = 1,
			Fourth = 1,
			Fifth = 1,
		},
		DamageTypeModifier = "Regular",
		HitboxInfo = {
			["Right Arm"] = {
				HitboxSize = Vector3.new(4, 4, 4),
				HitboxPosition = Vector3.new(0, -0.5, 0),
				HitboxOrientation = Vector3.new(0, 0, 0),
			},
			["Left Arm"] = {
				HitboxSize = Vector3.new(4, 4, 4),
				HitboxPosition = Vector3.new(0, -0.5, 0),
				HitboxOrientation = Vector3.new(0, 0, 0),
			},
		},
		RagdollTimeModifier = 1,
		EffectName = "NoWeapon",
		BlockInteractionModifier = "blockable",
		FrameHealthReduction = 5,
		SecondarySkillModifier = "HEAVY SWING",
		HitboxLocation = "Arms",
		StunTimeModifier = 1, 
		PossibleStyles = {"Fists"},
		WeldLocation = {"Left Arm","Right Arm"},
		WeldInfo = {
			Position = Vector3.new(0, -1, 0),      
			Orientation = Vector3.new(0, 0, 90),    
		},
		BackWeldInfo = {
			Position = Vector3.new(0, 0, 1),        
			Orientation = Vector3.new(0, 0, 45),    
		},
		UnequipLocation = "None",
		AttackInfo = {
			First = {
				Blockable = true,
				StunType = "TrueStunned",
				BlockDamage = 5,
			},
			Second = {
				Blockable = true,
				StunType = "TrueStunned",
				BlockDamage = 5,
			},
			Third = {
				Blockable = true,
				StunType = "SoftStunned",
				BlockDamage = 5,
			},
			Fourth = {
				Blockable = true,
				StunType = "TrueStunned",
				BlockDamage = 5,
			},
			Fifth = {
				Blockable = true,
				StunType = "TrueStunned",
				BlockDamage = 5,
			},
			
		}
	}, 

	LegBrace = {
		DamageModifier = 1.1,
		--[[StatusBuffs = {
			{	Type = whattypeofbuffsoitcanbeyourstatusbuffsorwhatever,
				Name = Nameofthebuffadded,
				Amount = howmuch of thebuff you want to give
			}
		},]]--
		ComboRefreshTimeModifier = 1,
		SwingSpeedModifier = 1.2,
		DebounceTimeModifier = 1.1,
		StaminaUsageModifier = 1.15,
		AnimSpeedsModifier = {
			First = 1,
			Second = 1,
			Third = 1,
			Fourth = 1,
			Fifth = 1,
		},
		DamageTypeModifier = "Regular",
		HitboxSizeModifier = Vector3.new(5,5,5),
		RagdollTimeModifier = 1,
		EffectName = "NoWeapon",
		BlockInteractionModifier = "blockable",
		FrameHealthReduction = 5,
		SecondarySkillModifier = "None",
		HitboxLocation = "Legs",
		StunTimeModifier = 1, 
		PossibleStyles = {"Fists"},
		WeldLocation = {"Left Leg","Right Leg"},
		WeldInfo = {
			Position = Vector3.new(0, -1, 0),      
			Orientation = Vector3.new(0, 0, 90),    
		},
		BackWeldInfo = {
			Position = Vector3.new(0, 0, 1),        
			Orientation = Vector3.new(0, 0, 45),    
		},
		UnequipLocation = "None",
		AttackInfo = {
			First = {
				Blockable = true,
				StunType = "TrueStunned",
				BlockDamage = 5,
			},
			Second = {
				Blockable = true,
				StunType = "TrueStunned",
				BlockDamage = 5,
			},
			Third = {
				Blockable = true,
				StunType = "SoftStunned",
				BlockDamage = 5,
			},
			Fourth = {
				Blockable = true,
				StunType = "TrueStunned",
				BlockDamage = 5,
			},
			Fifth = {
				Blockable = true,
				StunType = "TrueStunned",
				BlockDamage = 5,
			},

		}
	}, 
	
	DefaultKatana = {
		DamageModifier = 1,
		--[[StatusBuffs = {
			{	Type = whattypeofbuffsoitcanbeyourstatusbuffsorwhatever,
				Name = Nameofthebuffadded,
				Amount = howmuch of thebuff you want to give
			}
		},]]--
		ComboRefreshTimeModifier = 1,
		SwingSpeedModifier = .85,
		DebounceTimeModifier = 1.15,
		StaminaUsageModifier = 1.15,
		AnimSpeedsModifier = {
			First = 1,
			Second = 1,
			Third = 1,
			Fourth = 1,
			Fifth = 1,
		},
		DamageTypeModifier = "Regular",
		HitboxInfo = {
			["Katana"] = {
				HitboxSize = Vector3.new(0.29, 4.733, 0.46),
				HitboxPosition = Vector3.new(0, 0, -0.5),
				HitboxOrientation = Vector3.new(0, 0, 0),
			},
		},
		RagdollTimeModifier = 1,
		EffectName = "SlashWeapon",
		BlockInteractionModifier = "blockable",
		FrameHealthReduction = 5,
		SecondarySkillModifier = "None",
		HitboxLocation = "Weapon",
		PossibleStyles = {"Katana"},
		StunTimeModifier = 1, 
		WeldLocation = {"Right Arm"},
		WeldInfo = {
			Position = Vector3.new(0.01, -1.03, 0.152),      
			Orientation = Vector3.new(-0, 180, 180),    
		},
		BackWeldInfo = {
			Position = Vector3.new(-1, -1, -1),        
			Orientation = Vector3.new(0, -5, 35),    
		},
		UnequipLocation = "Back",
		AttackInfo = {
			First = {
				Blockable = true,
				StunType = "TrueStunned",
				BlockDamage = 5,
			},
			Second = {
				Blockable = true,
				StunType = "TrueStunned",
				BlockDamage = 5,
			},
			Third = {
				Blockable = true,
				StunType = "SoftStunned",
				BlockDamage = 5,
			},
			Fourth = {
				Blockable = true,
				StunType = "TrueStunned",
				BlockDamage = 5,
			},
			Fifth = {
				Blockable = true,
				StunType = "TrueStunned",
				BlockDamage = 5,
			},

		},
	}, 
	
	DefaultBisento = {
		DamageModifier = 1,
		--[[StatusBuffs = {
			{	Type = whattypeofbuffsoitcanbeyourstatusbuffsorwhatever,
				Name = Nameofthebuffadded,
				Amount = howmuch of thebuff you want to give
			}
		},]]--
		ComboRefreshTimeModifier = 1,
		SwingSpeedModifier = 1,
		DebounceTimeModifier = 1.15,
		StaminaUsageModifier = 1.15,
		AnimSpeedsModifier = {
			First = 1,
			Second = 1,
			Third = 1,
			Fourth = 1,
			Fifth = 1,
		},
		DamageTypeModifier = "Regular",
		HitboxInfo = {
			["Bisento"] = {
				HitboxSize = Vector3.new(1, 1, 1.668),
				HitboxPosition = Vector3.new(0, 3.5, 0),
				HitboxOrientation = Vector3.new(90, 0, 0),
			},
		},
		RagdollTimeModifier = 1,
		EffectName = "SlashWeapon",
		BlockInteractionModifier = "blockable",
		FrameHealthReduction = 5,
		SecondarySkillModifier = "None",
		HitboxLocation = "Weapon",
		PossibleStyles = {"Katana"},
		WeldLocation = {"Right Arm"},
		WeldInfo = {
			Position = Vector3.new(0.041, -1.069, 0.055),      
			Orientation = Vector3.new(0, 0, 180),    
		},
		BackWeldInfo = {
			Position = Vector3.new(0, 0, 0.5),        
			Orientation = Vector3.new(35, -90, 35),    
		},
		UnequipLocation = "Back",
		AttackInfo = {
			First = {
				Blockable = true,
				StunType = "TrueStunned",
				BlockDamage = 5,
				Blocklock = .35,
				StunTimeModifier = 1, 
			},
			Second = {
				Blockable = true,
				StunType = "TrueStunned",
				BlockDamage = 5,
				Blocklock = nil,
				StunTimeModifier = 1, 
			},
			Third = {
				Blockable = true,
				StunType = "SoftStunned",
				BlockDamage = 5,
				Blocklock = nil,
				StunTimeModifier = 1, 
			},
			Fourth = {
				Blockable = true,
				StunType = "TrueStunned",
				BlockDamage = 5,
				Blocklock = nil,
				StunTimeModifier = 1, 
			},
			Fifth = {
				Blockable = true,
				StunType = "TrueStunned",
				BlockDamage = 5,
				Blocklock = .35,
				StunTimeModifier = 1, 
			},

		},
	}, 

}

return WeaponInfoTable