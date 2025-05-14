extends Control

@export var menu_btn: Control;
@export var room_name: Control;

@export var room_name_input: LineEdit;
@export var error_label: Label;

@export var main_game: PackedScene;

func mouse_enter_button_sfx() -> void:
	if get_tree() != null:
		$"/root/SoundControl".play_sfx("menu_hover");
	
func mouse_click_button_sfx() -> void:
	if get_tree() != null:
		$"/root/SoundControl".play_sfx("menu_click");

func exit_btn() -> void:
	get_tree().quit();

func back_to_main() -> void:
	menu_btn.show();
	room_name.hide();
	error_label.text = "";
	
func start_game() -> void:
	if room_name_input.text.replace(" ", "") == "":
		error_label.text = "Room name cannot be empty."
	else:
		NetworkManager.room_name = room_name_input.text;
		NetworkManager.start_broadcast();
		get_tree().change_scene_to_packed(main_game);
	
func show_room_name() -> void:
	menu_btn.hide();
	room_name.show();
