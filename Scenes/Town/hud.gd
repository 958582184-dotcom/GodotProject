extends CanvasLayer

class_name  HUD

@onready var equipment_panel: EquipmentPanel = %EquipmentPanel
@onready var inventory_panel: InventortPanel = %InventoryPanel
@onready var stats_panel: EquipmentPanel = %StatsPanel
@onready var skills_panel: PanelContainer = %SkillsPanel

@onready var health_bar: ProgressBar = $HealthBar
@onready var mana_bar: ProgressBar = $ManaBar
@onready var exp_bar: ProgressBar = $ExpBar

@onready var health_label: Label = %HealthLabel
@onready var mana_label: Label = %ManaLabel


func _ready() -> void:
	EventBus.on_player_health_updated.connect(_on_player_health_updated)
	EventBus.on_player_mana_updated.connect(_on_player_mana_updated)
	EventBus.on_player_new_level.connect(_on_player_new_level)

func _on_equipment_button_pressed() -> void:
	equipment_panel.visible	= !equipment_panel.visible
	pass # Replace with function body.


func _on_inventory_button_pressed() -> void:
	inventory_panel.visible	= !inventory_panel.visible
	pass # Replace with function body.

func _on_statts_button_pressed() -> void:
	stats_panel.visible	= !stats_panel.visible
	pass # Replace with function body.

func _on_skill_button_pressed() -> void:
	skills_panel.visible	= !skills_panel.visible
	pass # Replace with function body.
	
func _on_player_health_updated(_curr:float, _max:float) -> void:
	health_bar.value = _curr/_max
	health_label.text = "%d/%d" % [_curr, _max]
	pass
func _on_player_mana_updated(_curr:float, _max:float) -> void:
	mana_bar.value = _curr/_max
	mana_label.text = "%d/%d" % [_curr, _max]
	pass
	
func _on_player_new_level(curr:float, new_level:float) -> void:
	exp_bar.value = curr/new_level
	pass
