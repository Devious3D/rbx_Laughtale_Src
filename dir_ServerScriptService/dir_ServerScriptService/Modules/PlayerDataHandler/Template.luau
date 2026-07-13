return {

	Quests = {},

	Inventory = {
		metadata = {
			InvWeight = 0,
			MaxInvWeight = 100
		},

		Hotbar = {}
	},

	EquippedItems = {
		HeadAccessory = "",
		Headpiece = "",
		NeckAccessory = "",
		LeftArmAccessory = "",
		Shirt = "",
		RightArmAccessory = "",
		LeftLegAccessory = "",
		Pants = "",
		RightLegAccessory = "",
		Shoes = "",
		Outerwear = "",

		PrimaryStyle = "",
		SubStyle = "",
		BindedWeapon = "",
	},

	Experiences = {
		metadata = {},

		Muscle = 0,
		Buso = 0,
		Ken = 0,
		Conquerors = 0,
		FistExp = 0,
		SwordExp = 0,
		SlashingWeaponExp = 0,
		BluntWeaponExp = 0,
		RangedWeaponExp = 0,
		ReachWeaponsExp = 0,
		FlexibleWeaponsExp = 0,
		ElementalWeaponsExp = 0,
		TechWeaponsExp = 0,
		FirearmExp = 0,
		KickExp = 0,
		stealth = 0,
		OverallCombatExp = 0,
		Agility = 0,
		Intelligence = 0,
		ExplorationExp = 0,
	},

	PlayerStatus = {
		metadata = {
			raceSet = false,
			appearanceSet = false,
			appearanceLoaded = false
		},
		
		Name = "",
		Gender = "Male",
		Title = "",

		Beli = 0,

		Health = 100,
		Thirst = 100,
		Hunger = 100,

		Faction = {"None", "0"},

		Appearance = {EyebrowType = "", EyeType = "", MouthType = "", PrimaryHairType = "", SecondaryHairType = "", HairColor1 = "", HairColor2 = "", TempFace = ""},
		Race = {Main = "None", Sub = "Regular", SkinColor = "", Tertiary = "", Scale = 1, Clan = ""},
		--LimbHP = {Head = 500, Torso = 500, RightArm = 500, LeftArm = 500, RightLeg = 500, LeftLeg = 500},
		Injuries = {Head = {}, Torso = {}, RightArm = {}, LeftArm = {}, RightLeg = {}, LeftLeg = {}},
	},



	--ShipPartInventory = {},
	--ShipStorage = {},
	--CrewData = {},

	KeybindData = {
		Run = {Enum.KeyCode.W.Name},
		Attack = {Enum.KeyCode.MouseLeftButton.Name},
		Inventory = {Enum.KeyCode.Backquote.Name},
		Block = {Enum.KeyCode.F.Name},
		Equip = {Enum.KeyCode.E.Name},
		Emotes = {Enum.KeyCode.K.Name},
		Menu = {Enum.KeyCode.M.Name},
		Crouch = {Enum.KeyCode.C.Name},
		HighJump = {Enum.KeyCode.T.Name},
		Dash = {Enum.KeyCode.Q.Name},
		TestKey = {Enum.KeyCode.L.Name}
	},

	--Ships = {},
	NPCRelations = {},
	AreasExplored = {},

	UpdateVersion = 0,
}
