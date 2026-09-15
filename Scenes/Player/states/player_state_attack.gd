extends PlayerState
class_name PlayerStateAttack

var weapon_rotation:Dictionary = {
	"down": 180.0,
	"left": -90.0,
	"right": 90.0,
	"up":0.0
}


func enter_state() -> void:
	player.play_direction_anim("attack")
	position_weapon()
	player.anim_sprite.animation_finished.connect(_on_animation_finished)
	pass
func exit_state()-> void:
	if player.anim_sprite.animation_finished.is_connected(_on_animation_finished):
		player.anim_sprite.animation_finished.disconnect(_on_animation_finished)
	pass
func process_state( delta: float)->void:
	pass

func position_weapon()->void:
	var direction_key : String = player.last_direction
	var marker: Marker2D = player.attack_positions[direction_key]
	player.weapon.global_position = marker.global_position
	player.weapon.rotation_degrees = weapon_rotation[direction_key]
	player.weapon.show()
	player.enable_weapon_collision(true)
	
func _on_animation_finished()->void:
	player.enable_weapon_collision(false)
	player.weapon.hide()
	fsm.transition_to("Idle")
