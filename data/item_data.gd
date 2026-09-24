extends Item
class_name ItemData

enum Type{
	FOOD,
	ORE,
	POTION,
	SCROLL,
	EQUIPMENT
}

@export var type: Type
@export var is_consumable: bool
@export var max_stack: int = 64
@export_group("Consumable")
@export var value:float
