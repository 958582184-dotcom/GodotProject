extends Resource
class_name SlotData

@export var item: ItemData
@export var quantity: int = 1



func _init(_item: ItemData, _quantity: int) -> void:
	item = _item
	quantity = _quantity
