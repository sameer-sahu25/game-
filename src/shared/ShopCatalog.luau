--!strict

export type ShopItem = {
	id: string,
	name: string,
	kind: "fighter" | "cosmetic",
	cost: number,
	fighterId: string?,
	description: string,
}

local ShopCatalog: { ShopItem } = {
	{
		id = "unlock_ThunderRonin",
		name = "Thunder Ronin",
		kind = "fighter",
		cost = 400,
		fighterId = "ThunderRonin",
		description = "Unlock Thunder Ronin with Battle Coins.",
	},
	{
		id = "unlock_InfernoTitan",
		name = "Inferno Titan",
		kind = "fighter",
		cost = 500,
		fighterId = "InfernoTitan",
		description = "Unlock Inferno Titan with Battle Coins.",
	},
	{
		id = "unlock_VoidPhantom",
		name = "Void Phantom",
		kind = "fighter",
		cost = 600,
		fighterId = "VoidPhantom",
		description = "Unlock Void Phantom with Battle Coins.",
	},
	{
		id = "unlock_SolarGuardian",
		name = "Solar Guardian",
		kind = "fighter",
		cost = 650,
		fighterId = "SolarGuardian",
		description = "Unlock Solar Guardian with Battle Coins.",
	},
	{
		id = "unlock_Windblade",
		name = "Windblade",
		kind = "fighter",
		cost = 700,
		fighterId = "Windblade",
		description = "Unlock Windblade with Battle Coins.",
	},
	{
		id = "unlock_ArcaneMage",
		name = "Arcane Mage",
		kind = "fighter",
		cost = 800,
		fighterId = "ArcaneMage",
		description = "Unlock Arcane Mage with Battle Coins.",
	},
	{
		id = "aura_neon",
		name = "Neon Aura",
		kind = "cosmetic",
		cost = 200,
		description = "Lobby/profile aura. No combat advantage.",
	},
	{
		id = "trail_cyan",
		name = "Cyan Attack Trail",
		kind = "cosmetic",
		cost = 180,
		description = "Cosmetic trail only.",
	},
	{
		id = "badge_legend",
		name = "Legend Badge",
		kind = "cosmetic",
		cost = 120,
		description = "Profile badge.",
	},
}

return ShopCatalog
