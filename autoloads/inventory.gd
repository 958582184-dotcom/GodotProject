extends Node

signal  on_inventory_changed
signal  on_equipment_changed


const INVENTORY_SIZE: int = 30
var inventory: Array[SlotData]

func _ready() -> void:
	inventory.clear()
	inventory.resize(INVENTORY_SIZE)

#region Find item

#返回全部空白格子
func _get_empty_slot_indexed()-> Array[int]:
	var empty_index: Array[int] = []
	for i in inventory.size():
		if inventory[i] == null:
			empty_index.append(i)
	return empty_index
#查找对应物品

func find_item_indexes(item: ItemData, with_space:bool = false)-> Array[int]:
	var find: Array[int] = []
	for i in inventory.size():
		var slot = inventory[i]
		if slot and slot.item == item:
			if with_space and slot.quantity >= item.max_stack:
				continue
			find.append(i)
	return find

func get_slot_item(index:int )-> ItemData:
	var slot = get_slot(index)
	if slot:
		return slot.item
	return


func get_slot(index: int) -> SlotData:
	if index >= 0 and index < inventory.size():
		return inventory[index]
	return null


#endregion 

#region Add / remove
func add_item(item: ItemData, amound:int = 1)-> void:
	if not item: 
		return
	var remaining = amound
	
	#找到相同物品，有堆叠空间则继续堆叠
	#堆叠空间不够则找下一个相同物品格子或空白格子
	if item.max_stack > 1:
		for index in find_item_indexes(item, true):
			if remaining <= 0:
				break
			var slot  = inventory[index]
			var space = item.max_stack - slot.quantity
			var to_give = min(space, remaining)
			
			slot.quantity += to_give
			remaining -= to_give
	#到这就需要找空白格子了
	if remaining > 0:
		for index in _get_empty_slot_indexed():
			if remaining <= 0:
				break
			var to_give = min(item.max_stack, remaining)
			#实例化对应数量
			inventory[index] = SlotData.new(item, to_give)
			remaining -= to_give
	var added = amound - remaining
	#通知
	if added > 0:
		on_inventory_changed.emit()
#endregion

#region Use Item
func use_item(slot_index: int) -> void:
	var slot:SlotData = get_slot(slot_index)
	if not slot: return
	if not slot.item.is_consumable: return
	
	slot.quantity -= 1
	if slot.quantity <= 0:
		inventory[slot_index] = null
	
	on_inventory_changed.emit()


func can_use_item(slot_index: int)-> bool:
	var slot:SlotData = get_slot(slot_index)
	return slot and slot.item.is_consumable
#endregion
	
#region Move slots
func swap_slot(from_index: int, to_index: int) -> void:
	if from_index <0 or from_index >= inventory.size():
		return
	if to_index <0 or to_index >= inventory.size():
		return
	var slot = inventory[from_index]
	inventory[from_index] = inventory[to_index]
	inventory[to_index] = slot
	on_inventory_changed.emit()
	pass

func merge_slot(from_index: int, to_index: int) -> void:
	if from_index <0 or from_index >= inventory.size():
		return
	if to_index <0 or to_index >= inventory.size():
		return
	var from_slot = get_slot(from_index)
	var to_slot = get_slot(to_index)
	
	if not from_slot or not to_slot:
		return
	if from_slot.item != to_slot.item:
		return
	
	var item = from_slot.item
	#不能堆叠
	if item.max_stack <= 1:
		return
	
	var space = item.max_stack - to_slot.quantity
	var to_move = min(space, from_slot.quantity)
	to_slot.quantity += to_move
	from_slot.quantity -= to_move
	
	if from_slot.quantity <= 0:
		inventory[from_index] = null
	elif space <= 0:
		swap_slot(from_index, to_index)
	
	on_inventory_changed.emit()
	pass
#endregion
