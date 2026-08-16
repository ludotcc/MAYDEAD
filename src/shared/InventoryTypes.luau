export type InventorySlot = {
	ItemId: string?,
	Quantity: number,
	WaterCharges: number?,
}

export type InventoryState = {
	Slots: { InventorySlot },
	ActiveQuickSlot: number,
	InventoryVersion: number?,
}

return {}
