extends Node

func back_to_menu():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn");
	var data : Dictionary = {
		action = "close_session"	
	};
	var json: String = JSON.stringify(data);
	NetworkManager.broadcast_message(json);
	NetworkManager.reset_broadcast();
	NetworkManager.conn_array = [];
