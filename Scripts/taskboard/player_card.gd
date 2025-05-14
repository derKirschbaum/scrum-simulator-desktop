extends Panel

var ini_pos: Vector2;
var player_name: String = "";
var player_id : String = "";
var current_task: String = "";
var is_showing: bool = false;

var game_manager: Node;

func _ready():
	
	ini_pos = self.position;
	$Player_name.text = player_name;
	$Current_task.text = "Task: " + current_task;
	
	game_manager = get_node("/root/Main");
	
func task_enter(node: Node2D):
	if !game_manager.taskboard_is_card_showing:
		self.position.y -= 16;
		game_manager.taskboard_is_card_showing = true;
		game_manager.current_chosen_player = player_id;
		is_showing = true;
		$Current_task.text = "Task: " + node.task_name;
	
func task_leave(node: Node2D):
	if is_showing:
		self.position.y += 16;
		$Current_task.text = "Task: " + current_task;
		game_manager.current_chosen_player = "";
		is_showing = false;
		game_manager.taskboard_is_card_showing = false;
	
