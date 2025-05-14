extends Node

@export_category("Prefabs")
@export var task_card: PackedScene;

@export_category("Column Highlighter")
@export var backlog_hightlight: Panel;
@export var todo_highlight: Panel;

@export_category("Column area")
@export var backlog_area: Area2D;
@export var todo_area: Area2D;

var player_textures: Array[Texture2D];

var choose_player_btns: Array[Button];

var is_in_column: bool = false;

var current_dragged_task : Node2D;

var task_board_obj : Array[Node];

var rand: RandomNumberGenerator = RandomNumberGenerator.new();

var start_pos_of_inprogress : Vector2 = Vector2(826, 20);
var task_inprogress_count: int = 0;
var emergency_task_count: int = 0;

var emergency_task_added : Array = [];
var start_pos_of_done: Vector2 = Vector2(1294, 20);
var task_done_count: int = 0;

var phase1_task_list : Array[Task];
var phase2_task_list: Array[Task];
var phase3_task_list: Array[Task];
var emergency_task_list: Array[Task];

const BOARD_COLUMN: Dictionary = {
	BACKLOG = 0,
	TODO = 1,
	INPROGRESS = 2,
	DONE = 3
};

var game_manager: Node;

func _ready():
	var p1_str = FileAccess.open("res://Assets/phase1_tasks.json", FileAccess.READ).get_as_text();
	var p1_json = JSON.parse_string(p1_str);
		
	for t in p1_json:
		var task = Task.new();
		task.task_name = t.task_name;
		task.task_energy_consumption = t.task_energy_consumption;
		task.task_id = t.task_id;
		task.task_effect = t.task_effect;
		task.task_game = t.task_game;
		task.task_difficulty = t.task_difficulty;
		task.task_description = t.task_description;

		phase1_task_list.append(task);
		
	var p2_str = FileAccess.open("res://Assets/phase2_tasks.json", FileAccess.READ).get_as_text();
	var p2_json = JSON.parse_string(p2_str);
		
	for t in p2_json:
		var task = Task.new();
		task.task_name = t.task_name;
		task.task_energy_consumption = t.task_energy_consumption;
		task.task_id = t.task_id;
		task.task_effect = t.task_effect;
		task.task_game = t.task_game;
		task.task_difficulty = t.task_difficulty;
		task.task_description = t.task_description;

		phase2_task_list.append(task);
		
	var p3_str = FileAccess.open("res://Assets/phase3_tasks.json", FileAccess.READ).get_as_text();
	var p3_json = JSON.parse_string(p3_str);
		
	for t in p3_json:
		var task = Task.new();
		task.task_name = t.task_name;
		task.task_energy_consumption = t.task_energy_consumption;
		task.task_id = t.task_id;
		task.task_effect = t.task_effect;
		task.task_game = t.task_game;
		task.task_difficulty = t.task_difficulty;
		task.task_description = t.task_description;

		phase3_task_list.append(task);
		
	var em_str = FileAccess.open("res://Assets/emergency_tasks.json", FileAccess.READ).get_as_text();
	var em_json = JSON.parse_string(em_str);
		
	for t in em_json:
		var task = Task.new();
		task.task_name = t.task_name;
		task.task_energy_consumption = t.task_energy_consumption;
		task.task_id = t.task_id;
		task.task_effect = t.task_effect;
		task.task_game = t.task_game;
		task.task_difficulty = t.task_difficulty;
		task.task_description = t.task_description;

		emergency_task_list.append(task);

func assign_task_to_player(player_id : String, player_color : int):
	current_dragged_task.assigned_to_id = player_id;
	current_dragged_task.color = player_color;
	
	for player : Player in game_manager.player_list:
		if player.player_id == player_id:
			player.current_task.append(current_dragged_task.task);
			(player.main_player_card.get_child(1) as Label).text = "Task: " + str(len(player.current_task));
			
			var data : Dictionary = {
					action = "update_task",
					task = []
				};
			
			for task : Task in player.current_task:
				var new_task : Dictionary = {
						task_name = task.task_name,
						task_id = task.task_id,
						task_energy_consumption = task.task_energy_consumption,
						task_game = task.task_game,
						task_effect = task.task_effect,
						task_difficulty = task.task_difficulty
					}
					
				data.task.append(new_task);
				
			var json : String = JSON.stringify(data);
			
			print("Sent " + json);
				
			player.peer_connection.put_packet(json.to_utf8_buffer());
			
	(current_dragged_task.get_child(3) as Sprite2D).texture = game_manager.player_textures[player_color];
	hide_choose_player_btn();
		
	match player_color:
		
		GAME_COLOR.CODE.BLUE:
			(current_dragged_task.get_child(0) as ColorRect).color = GAME_COLOR.COLOR.BLUE;
			
		GAME_COLOR.CODE.GRAY:
			(current_dragged_task.get_child(0) as ColorRect).color = GAME_COLOR.COLOR.GRAY;
			
		GAME_COLOR.CODE.GREEN:
			(current_dragged_task.get_child(0) as ColorRect).color = GAME_COLOR.COLOR.GREEN;
			
		GAME_COLOR.CODE.ORANGE:
			(current_dragged_task.get_child(0) as ColorRect).color = GAME_COLOR.COLOR.ORANGE;
			
		GAME_COLOR.CODE.PINK:
			(current_dragged_task.get_child(0) as ColorRect).color = GAME_COLOR.COLOR.PINK;
			
		GAME_COLOR.CODE.RED:
			(current_dragged_task.get_child(0) as ColorRect).color = GAME_COLOR.COLOR.RED;
			
		GAME_COLOR.CODE.VIOLET:
			(current_dragged_task.get_child(0) as ColorRect).color = GAME_COLOR.COLOR.VIOLET;
			
		GAME_COLOR.CODE.YELLOW:
			(current_dragged_task.get_child(0) as ColorRect).color = GAME_COLOR.COLOR.YELLOW;
	
func show_choose_player_btn(task: Node2D):
	for i in range(len(choose_player_btns)):
		choose_player_btns[i].position = task.position + Vector2(350, 100 + (100 * i));
		choose_player_btns[i].visible = true;
		
func hide_choose_player_btn():
	for i in range(len(choose_player_btns)):
		choose_player_btns[i].visible = false;

func handle_release(task: Node2D):
	
	todo_highlight.visible = false;
	backlog_hightlight.visible = false;
	
	current_dragged_task = task;

	if task.column == BOARD_COLUMN.BACKLOG:
		
		(current_dragged_task.get_child(3) as Sprite2D).texture = null;
		(current_dragged_task.get_child(0) as ColorRect).color = GAME_COLOR.COLOR.DEFAULT_TASK;
		current_dragged_task.assigned_to_id = "";
		current_dragged_task.color = GAME_COLOR.CODE.DEFAULT_TASK;
		if !task.energy_added:
			game_manager.energy += task.task.task_energy_consumption;
			task.energy_added = true;
			task.energy_deducted = false;
		
	elif task.column == BOARD_COLUMN.TODO:
		if game_manager.energy - task.task.task_energy_consumption <= 0:
			task.return_to_original_pos();
			return;
			
		if !task.energy_deducted:
			game_manager.energy -= task.task.task_energy_consumption;
			task.energy_deducted = true;
			task.energy_added = false;
			show_choose_player_btn(task);
		
func start_drag(task: Node2D):
	hide_choose_player_btn();
	current_dragged_task = null;

func start_taskboard():
	game_manager = get_node("/root/Main");
	
	# Prepare player button
	for i in range(len(game_manager.player_list)):
		var ins : Button = load("res://Prefabs/assign_button.tscn").instantiate() as Button;
		ins.set_script(load("res://Scripts/taskboard/choose_player_btn.gd"));
		ins.get_child(0).texture = game_manager.player_textures[game_manager.player_list[i].color];
		ins.get_child(1).text = game_manager.player_list[i].player_name;
		ins.visible = false;
		ins.player_id = (game_manager.player_list[i] as Player).player_id;
		ins.player_color = game_manager.player_list[i].color;
		
		ins.assign_player.connect(assign_task_to_player);
		
		choose_player_btns.append(ins);
		
		self.call_deferred("add_child", ins);
	
		spawn_task();
	
		backlog_area.allow_highlight = true;
		todo_area.allow_highlight = true;

func spawn_task():
	# Spawn task here
	if game_manager.current_game_phase == 0 || game_manager.current_game_phase == 1:
		for i in range(15):
			
			var randomized: Array[int] = [];
			var ran : int = rand.randi_range(0, len(phase1_task_list) - 1);
			
			while ran in randomized:
				ran = rand.randi_range(0, len(phase1_task_list) - 1);
				
			randomized.append(ran);
			
			var ins: CharacterBody2D = task_card.instantiate();
			ins.task = phase1_task_list[ran];
		
			ins.position += Vector2(-30, (50 * i) + 50);
		
			ins.release_card.connect(handle_release);
			ins.start_drag.connect(start_drag);
			ins.move.connect(move_child);
			task_board_obj.append(ins);
			self.call_deferred("add_child", ins);
			
	if game_manager.current_game_phase == 2:
		for i in range(15):
			
			var randomized: Array[int] = [];
			var ran : int = rand.randi_range(0, len(phase2_task_list) - 1);
			
			while ran in randomized:
				ran = rand.randi_range(0, len(phase2_task_list) - 1);
				
			randomized.append(ran);
			
			var ins: CharacterBody2D = task_card.instantiate();
			ins.task = phase2_task_list[ran];
		
			ins.position += Vector2(50, (50 * i) + 75);
		
			ins.release_card.connect(handle_release);
			ins.start_drag.connect(start_drag);
			ins.move.connect(move_child);
			task_board_obj.append(ins);
			self.call_deferred("add_child", ins);
			
	if game_manager.current_game_phase == 3:
		for i in range(10):
			var randomized: Array[int] = [];
			var ran : int = rand.randi_range(0, len(phase3_task_list) - 1);
			
			while ran in randomized:
				ran = rand.randi_range(0, len(phase3_task_list) - 1);
				
			randomized.append(ran);
			
			var ins: CharacterBody2D = task_card.instantiate();
			ins.task = phase3_task_list[ran];
		
			ins.position += Vector2(130, (50 * i) + 100);
		
			ins.release_card.connect(handle_release);
			ins.start_drag.connect(start_drag);
			ins.move.connect(move_child);
			task_board_obj.append(ins);
			self.call_deferred("add_child", ins);
			
func add_emergency_task():
		var randomized : int = rand.randi_range(0, len(emergency_task_list) - 1);
		
		while randomized in emergency_task_added:
			randomized = rand.randi_range(0, len(emergency_task_list) - 1);
			
		emergency_task_added.append(randomized);
		
		var ins: CharacterBody2D = task_card.instantiate();
		ins.task = emergency_task_list[randomized];
		ins.isEmergency = true;
		ins.position += Vector2(160, (50 * emergency_task_count) + 100);
		ins.release_card.connect(handle_release);
		ins.start_drag.connect(start_drag);
		ins.move.connect(move_child);
		task_board_obj.append(ins);
		self.call_deferred("add_child", ins);
		
		emergency_task_count += 1;

func lock_task() -> void:
	for obj : Node in task_board_obj:
		if !is_instance_valid(obj) or !obj:
			continue;
			
		if obj.column == BOARD_COLUMN.TODO:
			obj.locked = true;
			
			if task_inprogress_count <= 15:
				obj.position = Vector2(start_pos_of_inprogress.x, start_pos_of_inprogress.y + (55 * task_inprogress_count))
			else:
				obj.position = Vector2(start_pos_of_inprogress.x + 150, start_pos_of_inprogress.y + (55 * (task_inprogress_count - 10)))
			
			task_inprogress_count += 1;
			
			
func complete_task(task_id: int) -> void:
	for obj: Node in task_board_obj:
		if !is_instance_valid(obj) or !obj:
			continue;
		
		if obj.task.task_id == task_id:
			obj.task.task_completed = true;
			if task_done_count <= 15:
				obj.position = Vector2(start_pos_of_done.x, start_pos_of_done.y + (55 * task_done_count));
			else:
				obj.position = Vector2(start_pos_of_done.x + 150, start_pos_of_done.y + (55 * task_done_count));
	task_done_count += 1;
	
func clear_unfinished_task() -> void:
	for obj: Node in task_board_obj:
		if !is_instance_valid(obj) or !obj:
			continue;
			
		if obj.assigned_to_id != "" && !obj.task.task_completed:
			obj.return_to_original_pos();
			(obj.get_child(3) as Sprite2D).texture = null;
			(obj.get_child(0) as ColorRect).color = GAME_COLOR.COLOR.DEFAULT_TASK;
			obj.color = GAME_COLOR.CODE.DEFAULT_TASK;
			game_manager.energy += obj.task.task_energy_consumption;
			obj.locked = false;
			obj.energy_deducted = false;
			
			#Remove from Player's
			var target_player : Player = game_manager.get_player_from_id(obj.assigned_to_id);
			var task_count: int = 0;
			for i in range(len(target_player.current_task) - 1, -1, -1):
				if obj.task.task_id == target_player.current_task[i].task_id:
					target_player.current_task.remove_at(i);
					task_count += 1;
					
			var new_task_list: Array[Dictionary] = [];
			for j in range(len(target_player.current_task)):
				var task : Task = target_player.current_task[j];
				var d: Dictionary = {
					task_id = task.task_id,
					task_name = task.task_name,
					task_effect = task.task_effect,
					task_energy_consumption = task.task_energy_consumption,
					task_game = task.task_game,
					task_difficulty = task.task_difficulty,
					task_completed = task.task_completed,
					task_description = task.task_description
				};
				
				new_task_list.append(d);
					
			var data: Dictionary ={
				action = "fail_task",
				task = new_task_list,
				task_failure_count = task_count
			};
			
			var json: String = JSON.stringify(data);
			
			target_player.peer_connection.put_packet(json.to_utf8_buffer());
			
			obj.assigned_to_id = "";
			
		elif obj.isEmergency && !obj.task.task_completed:
			game_manager.vic_sec += obj.task.task_effect.vic_sec;
			game_manager.vic_sur += obj.task.task_effect.vic_sur;
			game_manager.vic_dev += obj.task.task_effect.vic_dev;
			game_manager.int_morale += obj.task.task_effect.morale;
			game_manager.int_integrity += obj.task.task_effect.integrity;
			game_manager.int_health += obj.task.task_effect.health;
			game_manager.ext_env += obj.task.task_effect.environment;
			game_manager.ext_threat += obj.task.task_effect.threat;
			game_manager.max_energy += obj.task.task_effect.max_energy_mod;
			game_manager.energy_bar.max_value = game_manager.max_energy;
				
			obj.call_deferred("queue_free");

	
