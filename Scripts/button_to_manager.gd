extends Node

@export var msg: String = "";

func pressed():
	var game_manager: Node = get_node("/root/Main");
	game_manager.handle_button(msg);
