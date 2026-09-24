extends Node

signal on_player_created()
signal on_player_health_updated(curr:float, max:float)
signal on_player_mana_updated(curr:float, max:float)


signal on_player_new_level(curr:float, new_level:float)
signal on_player_state_updated()
signal on_inventory_used_item(item:ItemData)
