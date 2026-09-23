extends PanelContainer
class_name InventortPanel

@export var grabbed_slot : InventorySlot
@onready var container: GridContainer = %Container
@onready var gold_label: Label = %GoldLabel

var slots: Array[InventorySlot]
var selected_slot_index: int = -1

func _ready() -> void:
	Inventory.on_inventor_changed.connect(_on_inventor_changed)
	for i in container.get_child_count():
		var slot: InventorySlot = container.get_child(i)
		slot.on_slot_clicked.connect(_on_slot_clicked)
		slot.on_slot_hover.connect(_on_slot_hover)
		slot.slot_index = i
		slots.append(slot)
	
func  _process(delta: float) -> void:
	if grabbed_slot.visible:
		grabbed_slot.global_position = get_global_mouse_position()
		
		
func select_slot(slot_index: int)-> void:
	deselect_slot()
	selected_slot_index = slot_index
	var slot:SlotData = Inventory.get_slot(slot_index)
	grabbed_slot.load_data(slot)
	grabbed_slot.show()
	pass
func deselect_slot()-> void:
	selected_slot_index = -1
	grabbed_slot.hide()
	pass
func handle_left_button(slot_index: int)-> void:
	#当前有选中项且目标有效
	if selected_slot_index >= 0  and selected_slot_index != slot_index:
		var from_item = Inventory.get_slot_item(selected_slot_index)
		var to_item = Inventory.get_slot_item(slot_index)
		if from_item and to_item and from_item == to_item:
			Inventory.merge_slot(selected_slot_index, slot_index)
		else:
			Inventory.swap_slot(selected_slot_index, slot_index)
		deselect_slot()
	else:
		#反选
		if selected_slot_index == slot_index:
			deselect_slot()
		else:
			#选中第一个
			if Inventory.get_slot(slot_index):
				select_slot(slot_index)
	pass
func handle_right_button(slot_index: int)-> void:
	pass



func _on_inventor_changed():
	for i in slots.size():
		var slot: SlotData  = Inventory.get_slot(i)
		slots[i].load_data(slot)
	pass
func _on_slot_clicked(slot_index: int, button: int) -> void:
	match button:
		MOUSE_BUTTON_LEFT:
			handle_left_button(slot_index)
		MOUSE_BUTTON_RIGHT:
			handle_right_button(slot_index)
	pass
func _on_slot_hover(slot_index: int) -> void:
	pass
