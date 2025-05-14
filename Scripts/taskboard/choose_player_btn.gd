extends Button

var player_id: String = "";
var player_color : int = -1;

signal assign_player(player_id: String, player_color: int);

func _pressed():
	assign_player.emit(player_id, player_color);
	
