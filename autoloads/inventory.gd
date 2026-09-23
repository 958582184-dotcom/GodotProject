extends Node

signal  on_inventor_changed
signal  on_equipment_changed


const INVENTORY_SIZE: int = 30
var invenroty: Array[SlotData]

func _ready() -> void:
	invenroty.clear()
	invenroty.resize(INVENTORY_SIZE)


#返回全部空白格子
func _get_empty_slot_indexed()-> Array[int]:
	var empty_index: Array[int] = []
	for i in invenroty.size():
		if invenroty[i] == null:
			empty_index.append(i)
	return empty_index
#查找对应物品
func find_item_indexes(item: ItemData, with_space:bool = false)-> Array[int]:
	var find: Array[int] = []
	for i in invenroty.size():
		var slot = invenroty[i]
		if slot and slot.item == item:
			if with_space and slot.quantity >= item.max_stack:
				continue
			find.append(i)
	return find

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
			var slot  = invenroty[index]
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
			invenroty[index] = SlotData.new(item, to_give)
			remaining -= to_give
	var added = amound - remaining
	#通知
	if added > 0:
		on_inventor_changed.emit()

func swap_slot(from_index: int, to_index: int) -> void:
	if from_index <0 or from_index >= invenroty.size():
		return
	if to_index <0 or to_index >= invenroty.size():
		return
	var slot = invenroty[from_index]
	invenroty[from_index] = invenroty[to_index]
	invenroty[to_index] = slot
	on_inventor_changed.emit()
	pass

func merge_slot(from_index: int, to_index: int) -> void:
	if from_index <0 or from_index >= invenroty.size():
		return
	if to_index <0 or to_index >= invenroty.size():
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
		invenroty[from_index] = null
	elif space <= 0:
		swap_slot(from_index, to_index)
	
	on_inventor_changed.emit()
	pass


func get_slot_item(index:int )-> ItemData:
	var slot = get_slot(index)
	if slot:
		return slot.item
	return


func get_slot(index: int) -> SlotData:
	if index >= 0 and index < invenroty.size():
		return invenroty[index]
	return null
