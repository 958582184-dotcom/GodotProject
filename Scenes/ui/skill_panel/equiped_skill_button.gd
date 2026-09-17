extends Button
class_name EquipedSkillButton

@export var number:int 

@onready var emptyl: Panel = $Emptyl
@onready var skill_icon: TextureRect = $SkillIcon
@onready var label: Label = $Label

func 	_ready() -> void:
	label.text = str(number)
