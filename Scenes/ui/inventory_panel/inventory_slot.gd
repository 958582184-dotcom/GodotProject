extends Button
class_name InventorySlot

@onready var item_icon: TextureRect = $ItemIcon
@onready var amount_label: Label = $AmountLabel
@onready var selector: TextureRect = $Selector

signal on_slot_clicked(slot_index: int, button: int)
signal on_slot_hover(slot_index: int)


var slot_index: int = -1
var slot_data: SlotData

func load_data(data: SlotData):
	slot_data = data
	if slot_data and slot_data.item:
		item_icon.texture = slot_data.item.icon
		item_icon.show()
		
		if slot_data.quantity > 1:
			amount_label.text = str(slot_data.quantity)
			amount_label.show()
		else:
			amount_label.hide()
	else:
		clear_slot()
	
	pass


func clear_slot():
	amount_label.text = ""
	slot_data = null
	item_icon.texture = null
	item_icon.hide()
	amount_label.hide()


func _on_mouse_entered() -> void:
	selector.show()
	on_slot_hover.emit(slot_index)
	pass # Replace with function body.


func _on_mouse_exited() -> void:
	selector.hide()
	pass # Replace with function body.


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		on_slot_clicked.emit(slot_index, event.button_index)
	pass # Replace with function body.
