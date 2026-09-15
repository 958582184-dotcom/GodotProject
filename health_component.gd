extends Node
class_name HealthComponent


signal on_health_changed(current_health: float)
signal on_dead
var max_health : float
var current_health : float

func setup(value: float)->void:
	max_health = value
	current_health = value
	
	
func take_demage(value: float) ->void:
	if current_health<=0:
		return
	current_health = max(current_health-value,0)
	on_health_changed.emit(current_health)
	if current_health<=0:
		on_dead.emit()
