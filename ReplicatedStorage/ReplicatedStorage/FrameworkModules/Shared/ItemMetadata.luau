const IconData = require("../Shared/ItemIcons")


export type Item = {
	type: number,
	rarity: number,
	description: string,
	weight: number,
	icon: string,
	
	canBeDropped: boolean
}

const ItemTypes = {
	Misc = 0,
	Armor = 1,
	Food = 2,
	Currency = 3,
	Weapon = 4,
	Tool = 5,
	Skill = 6,
}

const ItemRarities = {
	Common = 0,
	Rare = 1,
	Epic = 2,
	Legendary = 3,
	Mythic = 4
}

const Items: {Item} = {
	TestMiscItem = {
		type = ItemTypes.Misc,
		rarity = ItemRarities.Common,
		description = "This is a Misc item.",
		weight = 1,
		icon = IconData.RootSword,
		canBeDropped = true,
	},
	TestArmorItem = {
		type = ItemTypes.Armor,
		rarity = ItemRarities.Common,
		description = "This is a Armor item.",
		weight = 1,
		icon = IconData.NightSword,
		canBeDropped = true,
	},
	TestFoodItem = {
		type = ItemTypes.Food,
		rarity = ItemRarities.Common,
		description = "This is a Food item.",
		weight = 1,
		icon = IconData.Donuts,
		canBeDropped = true,
	},
	TestCurrencyItem = {
		type = ItemTypes.Currency,
		rarity = ItemRarities.Common,
		description = "This is a Currency item.",
		weight = 1,
		icon = IconData.Apricot,
		canBeDropped = true,
	},
	TestWeaponItem = {
		type = ItemTypes.Weapon,
		rarity = ItemRarities.Common,
		description = "This is a Weapon item.",
		weight = 1,
		icon = IconData.DemonBloodSword,
		canBeDropped = true,
	},
	TestToolsItem = {
		type = ItemTypes.Tool,
		rarity = ItemRarities.Common,
		description = "This is a Tool item.",
		weight = 1,
		icon = IconData.ScarletSwrod,
		canBeDropped = true,
	},
	TestSkillItem = {
		type = ItemTypes.Skill,
		rarity = ItemRarities.Common,
		description = "This is a Skill item.",
		weight = 1,
		icon = IconData.PlasmaBullet,
		canBeDropped = false,
	},
}


return Items
