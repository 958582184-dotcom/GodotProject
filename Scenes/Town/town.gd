extends Node2D
class_name Town
@export var player_scene : PackedScene

func _ready() -> void:
	create_player()
	pass


func create_player() -> void:
	var player: Player = player_scene.instantiate()
	add_child(player)
	player.setup()
	EventBus.on_player_created.emit()
	pass
