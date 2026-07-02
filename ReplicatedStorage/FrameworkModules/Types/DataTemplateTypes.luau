

export type tFactionComponent = {
	name: string,
	reputation: number
}

export type tAppearanceComponent = {
	EyebrowType: string,
	EyeType: string,
	MouthType: string,
	PrimaryHairType: string,
	SecondaryHairType: string,
	HairColor1: string,
	HairColor2: string,
	TempFace: string
}

export type tRaceComponent = {
	Main: string,
	Sub: string,
 	SkinColor: string,
	Tertiary: string, 
 	Scale: number,
	Clan: string
}

export type tLimbStatusComponent = {
	Head: number, 
	Torso: number, 
	RightArm: number, 
	LeftArm: number, 
	RightLeg: number, 
	LeftLeg: number,
}

export type tExperiencesMetadataComponent = {
	
}

export type tInventoryMetadataComponent = {
	InvWeight: number,
	MaxInvWeight: number
}

export type tPlayerStatusMetadata = {
	raceSet: boolean,
	appearanceSet: boolean,
	appearanceLoaded: boolean
}

-------------------------------------------------
-------------------------------------------------

export type tExperiences = {
	metadata: tExperiencesMetadataComponent,
	
	MuscleExp: number,
	BusoExp: number,
	KenExp: number,
	ConquerorsExp: number,
	FistExp: number,
	SwordExp: number,
	SlashingWeaponExp: number,
	BluntWeaponExp: number,
	RangedWeaponExp: number,
	ReachWeaponsExp: number,
	FlexibleWeaponsExp: number,
	ElementalWeaponsExp: number,
	TechWeaponsExp: number,
	FirearmExp: number,
	KickExp: number,
	StealthExp: number,
	OverallCombatExp: number,
	AgilityExp: number,
	IntelligenceExp: number,
	ExplorationExp: number
}

export type tPlayerStatusData = {
	metadata: tPlayerStatusMetadata,
	
	Name:string,
	Gender:string,
	Title: string,

	Beli:number,

	Health: number,
	Thirst: number,
	Hunger: number,

	Faction:tFactionComponent,
	
	Appearance: tAppearanceComponent,
	Race: tRaceComponent,
	--LimbHP: tLimbStatusComponent,
	Injuries: {string},
}

export type tEquippedItems = {
	HeadAccessory: string,
	Headpiece: string,
	NeckAccessory: string,
	LeftArmAccessory: string,
	Shirt: string,
	RightArmAccessory: string,
	LeftLegAccessory: string,
	Pants: string,
	RightLegAccessory: string,
	Shoes: string,
	Outerwear: string,

	PrimaryStyle: string,
	SubStyle: string
}


export type tInventory = {
	metadata: tInventoryMetadataComponent,
	Hotbar: {any}
}

export type tKeybinds = {
	Run: string,
	Attack: string,
	Inventory: string,
	Block: string,
	Equip: string,
	Emotes: string,
	Menu: string,
	Crouch: string,
	HighJump: string,
	Dash: string,
	TestKey: string
}

-------------------------------------------------
-------------------------------------------------

export type tDataTemplate = {
	Quests: {any},
	EquippedItems: tEquippedItems,
	Exeriences: tExperiences,
	PlayerStatus: tPlayerStatusData,
	Keybinds:  tKeybinds,
	Inventory: tInventory
}

return {}
