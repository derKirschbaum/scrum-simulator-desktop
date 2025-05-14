extends Node

@export var cam: Camera3D

var is_open : bool = false

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		is_open = !is_open
		
		self.visible = is_open

func exit_game():
	get_tree().quit(0)
