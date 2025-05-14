extends Node

var music_volume: int;
var sfx_volume: int;

@export var bgm_player: AudioStreamPlayer;
@export var sfx_player: AudioStreamPlayer;

func change_music_playlist(clip: String) -> void:
	bgm_player["parameters/switch_to_clip"] = clip
	
func play_sfx(name: String):
	if name == "none":
		sfx_player.stop();
		
	elif sfx_player["parameters/switch_to_clip"] != name:
		sfx_player["parameters/switch_to_clip"] = name;
		sfx_player.play();
		
	else:
		sfx_player.play();

func update_bgm_volume(volume_db : float) -> void:
	var idx : int = AudioServer.get_bus_index("Music");
	
	AudioServer.set_bus_volume_db(idx, volume_db);
	
func update_sfx_volume(volume_db: float) -> void:
	var idx: int = AudioServer.get_bus_index("SFX");
	
	AudioServer.set_bus_volume_db(idx, volume_db);
	
func update_master_volume(volume_db: float) -> void:
	var idx: int = AudioServer.get_bus_index("Master");
	
	AudioServer.set_bus_volume_db(idx, volume_db);
	
