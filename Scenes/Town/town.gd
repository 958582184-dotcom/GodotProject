extends Node2D
class_name Town
@export var player_scene : PackedScene

func _ready() -> void:
	EventBus.on_inventory_used_item.connect(_on_inventory_used_item)
	create_player()
	
	pass


func create_player() -> void:
	var player: Player = player_scene.instantiate()
	add_child(player)
	player.setup()
	Refs.player = player
	EventBus.on_player_created.emit()
	pass

func _on_inventory_used_item(item: ItemData)-> void:
	Refs.player.health_component.heal(item.value)
	pass
