extends Node

@export_category("Prefabs")
@export var task_board: Control;
@export var player_card: PackedScene;
@export var char_selector: PackedScene;

@export_category("Screens")
@export var end_screen: Control;
@export var status_panel: Control;
@export var time_panel: Control;
@export var timer_panel: Control;
@export var energy_panel: Control;

@export_category("Controls")
@export var player_list_ui: Control;
@export var phase_label: Label
@export var day_number: Label;
@export var sprint_number: Label;
@export var timer_desc: RichTextLabel;
@export var timer_clock: Label;
@export var char_selector_scene: Control;
@export var energy_label: Label;
@export var task_button: Button;

@export_category("Max status")
@export var max_energy: int = 100;
@export var max_vic_score: int = 1000;
@export var int_max_morale: int = 300;
@export var int_max_integrity: int = 300;
@export var int_max_health: int = 300;
@export var ext_max_env: int = 300;
@export var ext_max_threat: int = 300;

@export_category("Bars")
@export var energy_bar: ProgressBar;
@export var vic_bar: ProgressBar;
@export var morale_bar: ProgressBar;
@export var int_bar: ProgressBar;
@export var health_bar: ProgressBar;
@export var env_bar: ProgressBar;
@export var threat_bar: ProgressBar;

@export_category("Timer")
@export var timer_node: Timer;
@export var max_meeting_time: int = 300;
@export var max_work_time: int = 300;
@export var max_review_time: int = 600;
@export var max_sprint_meeting: int = 600;
@export var max_day_per_sprint: int = 3;
@export var max_sprint_per_phase: int = 3;

@export_category("Networking")
@export var network_manager: Node;

@export_category("Numbers")
@export var chances_emergence_task: float = .2;

@export_category("Environments")
@export var cam: Sky_control;

@export_category("Buildings")
@export var buildings: Array[Node3D];

var energy: int;
var vic_sec: int;
var vic_sur: int;
var vic_dev: int;
var int_morale: int;
var int_integrity: int;
var int_health: int;
var ext_env: int;
var ext_threat: int = 0;

var vic_score: int = 0;
var vic_coeff_a: int = 0;
var vic_coeff_b: int = 0;
var vic_coeff_c: int = 0;

var taskboard_is_card_showing: bool = false;
var current_chosen_player : String = "";

var rand : RandomNumberGenerator = RandomNumberGenerator.new();

var player_card_init_pos : Vector2 = Vector2(0, 48);

var player_list: Array[Player] = [];
var player_count: int = 0;

var player_card_list: Array[Node] = [];

var building_revealed: Array[int] = [0, 6];

var player_textures : Array[Texture2D];

@export var emergency_chance: int = 50; #in percent

var current_game_phase: int = COLONY.PHASE.LANDING;

var current_day: int = 1;
var current_sprint: int = 1;
var current_timer_type: int = COLONY.TIMER.SPRINT_PLANNING;

func get_player_from_id(id: String) -> Player:
	for player in player_list:
		if player.player_id == id:
			return player;
			
	return null;
	

func handle_button(msg: String):
	if msg == "close_char_select":
		char_selector_scene.visible = false;
		timer_node.start();
		network_manager.stop_broadcast();
		task_board.start_taskboard();

func process_client_data(data: Dictionary):
	match data.action:
		"update-task":
			if data.task.task_status == "complete":
				var p = get_player_from_id(str(data.player_id));
				for task : Task in p.current_task:
					if task.task_id == data.task.task_id:
						task.task_completed = true;
					
						var effect = task.task_effect;
						vic_sec += effect.vic_sec;
						vic_sur += effect.vic_sur;
						vic_dev += effect.vic_dev;
						int_morale += effect.morale;
						int_integrity += effect.integrity;
						int_health += effect.health;
						ext_env += effect.environment;
						ext_threat += effect.threat;
						max_energy += effect.max_energy_mod;
						energy_bar.max_value = max_energy;
						
						task_board.complete_task(data.task.task_id);
						
						if task.task_name.to_lower().contains("build"):
							var randomized: int = rand.randi_range(0, len(buildings) - 1);
							
							while randomized in building_revealed:
								randomized = rand.randi_range(0, len(buildings) - 1);
								
							buildings[randomized].show();
							building_revealed.append(randomized);
		

func convert_time_to_string(seconds: float) -> String:
	
	var st : String = "";
	var minute: String = "%02d" % [ int(seconds/60) ];
	var second: String = "%02d" % [ int(ceil(seconds)) % 60 ];
	
	st = minute + ":" + second;
	
	return st;
	
func next_phase():
	
	current_timer_type = COLONY.TIMER.RETROSPECTIVE;
	timer_node.wait_time = max_review_time;
	
	if current_game_phase == COLONY.PHASE.LANDING:
		current_game_phase = COLONY.PHASE.FOUNDATION;
		
	elif current_game_phase == COLONY.PHASE.FOUNDATION:
		if int_health <= 80 || int_max_morale <= 80 || int_integrity <= 80:
			vic_sec -= 100;
			vic_dev -= 100;
			vic_sur -= 100;
			
		current_game_phase = COLONY.PHASE.EXPANSION;
		
	elif current_game_phase == COLONY.PHASE.EXPANSION:
		if int_health <= 160 || int_max_morale <= 160 || int_integrity <= 160:
			vic_sec -= 100;
			vic_dev -= 100;
			vic_sur -= 100;
		
		current_game_phase = COLONY.PHASE.SUSTAINMENT;
	
	elif current_game_phase == COLONY.PHASE.SUSTAINMENT:
		if int_health <= 240 || int_max_morale <= 240 || int_integrity <= 240:
			vic_sec -= 100;
			vic_dev -= 100;
			vic_sur -= 100;
			
		end_game();
		
	task_board.spawn_task();

func add_player(conn: PacketPeerUDP, player_id: String, player_name: String) -> Error:
	
	var player: Player = Player.new();
	player.player_id = player_id;
	player.peer_connection = conn;
	player.player_name = player_name;
	player.color = player_count;
	
	var response: Dictionary = {
		action = "handshake",
		data = {
			player_id = player_id,
			color = player_count
		}
	};
	
	conn.put_packet(JSON.stringify(response).to_utf8_buffer());
	
	var card : Node = player_card.instantiate();
	card.get_child(0).text = player_name;
	card.get_child(2).texture = player_textures[len(player_list)];
	card.position = player_card_init_pos + Vector2(0, 144 * len(player_list));
	player.main_player_card = card;
	player_list_ui.call_deferred("add_child", card);
	
	var player_se: Node = char_selector.instantiate();
	player_se.get_child(0).text = player_name;
	player_se.get_child(1).text = "Color: " + GAME_COLOR.COLOR_ARR[len(player_list)];
	player_se.get_child(2).texture = player_textures[len(player_list)];
	player_se.position = Vector2(60, 192 + (150 * len(player_list)));
	
	char_selector_scene.call_deferred("add_child", player_se);
	player_list.append(player);
	player_card_list.append(card);
	
	if len(player_list) == 5:
		network_manager.stop_broadcast();
	
	return OK;
	

func _ready() -> void:
	network_manager = $"/root/NetworkManager";
	
	network_manager.game_manager = self;
	
	energy = max_energy;
	
	energy_bar.max_value = max_energy;
	morale_bar.max_value = int_max_morale;
	int_bar.max_value = int_max_integrity;
	health_bar.max_value = int_max_health;
	env_bar.max_value = ext_max_env;
	threat_bar.max_value = ext_max_threat;
	
	vic_bar.max_value = max_vic_score;
	
	emergency_chance = 10 + round(ext_threat / ext_max_threat);
	
	var possible_coeff : Array[float] = [.5, 1.0, 2];
	
	vic_coeff_a = possible_coeff.pop_at(rand.randi_range(0, len(possible_coeff) - 1));
	vic_coeff_b = possible_coeff.pop_at(rand.randi_range(0, len(possible_coeff) - 1));
	vic_coeff_c = possible_coeff.pop_at(rand.randi_range(0, len(possible_coeff) - 1));
	
	ext_env = ext_max_env;
	
	for color in ["blue", "gray", "green", "orange", "pink", "red", "violet", "yellow"]:
		var texture = load("res://Assets/characters/" + color + ".png");
		
		player_textures.append(texture);
	
	
	timer_node.wait_time = max_meeting_time;
	
	char_selector_scene.visible = true;
	
func random_emergency_task() -> void:
	var randed_chances: int = rand.randi_range(0, 100);
	# Debug
	# randed_chances = 1;
	if randed_chances <= emergency_chance:
		task_board.add_emergency_task();

func _process(_delta) -> void:
	vic_bar.value = vic_score;
	morale_bar.value = int_morale;
	int_bar.value = int_integrity;
	health_bar.value = int_health;
	env_bar.value = ext_env;
	threat_bar.value = ext_threat;
	energy_bar.value = energy;
	
	if energy > max_energy:
		energy = max_energy;
		
	if vic_dev < 0:
		vic_dev = 0;
		
	if vic_sur < 0:
		vic_sur = 0;
	
	if vic_sec < 0: 
		vic_sec = 0;	
	
	if int_morale < 0:
		int_morale = 0;
		
	if int_integrity < 0:
		int_integrity = 0;
		
	if int_health < 0:
		int_health = 0;
	
	energy_label.text = "%d/%d" % [energy, max_energy];
	
	# Calculate victory score
	vic_score = ((vic_coeff_a * vic_sec) + (vic_coeff_b * vic_sur) + (vic_coeff_c * vic_dev)) - ((ext_max_env - ext_env) + ext_threat);

	# Update colony phase txt
	if current_game_phase == COLONY.PHASE.LANDING:
		phase_label.text = "Landing";
	elif current_game_phase == COLONY.PHASE.FOUNDATION:
		phase_label.text = "Foundation";
	elif current_game_phase == COLONY.PHASE.EXPANSION:
		phase_label.text = "Expansion";
	elif current_game_phase == COLONY.PHASE.SUSTAINMENT:
		phase_label.text = "Sustainment";
		
	# Update day and sprint
	sprint_number.text = str(current_sprint);
	day_number.text = str(current_day);
	
	# Update timer type
	if current_timer_type == COLONY.TIMER.SPRINT_PLANNING:
		timer_desc.text = "[font_size=45]Sprint Planning[/font_size]";
	elif current_timer_type == COLONY.TIMER.DAILY_MEETING:
		timer_desc.text = "[font_size=45]Daily Meeting[/font_size]";
	elif current_timer_type == COLONY.TIMER.WORKING:
		timer_desc.text = "[font_size=45]Working[/font_size]";
	elif current_timer_type == COLONY.TIMER.RETROSPECTIVE:
		timer_desc.text = "[font_size=23]Review & \nRetrospective[/font_size]";
		
	# Update timer
	timer_clock.text = convert_time_to_string(timer_node.time_left);

func next_timer():
	
	timer_node.stop();
	
	if current_timer_type == COLONY.TIMER.SPRINT_PLANNING && current_game_phase == COLONY.PHASE.LANDING:
		current_timer_type = COLONY.TIMER.WORKING;
		current_game_phase = COLONY.PHASE.FOUNDATION;
		
		task_board.lock_task();
		
		for player : Player in player_list:
			if len(player.current_task) > 0:
				var data : Dictionary = {
					action = "load_game",
				}
				var json : String = JSON.stringify(data);
				print("Sent ", json);
				player.peer_connection.put_packet(json.to_utf8_buffer());
	
	elif current_timer_type == COLONY.TIMER.SPRINT_PLANNING:
		current_timer_type = COLONY.TIMER.WORKING;
		timer_node.wait_time = max_work_time;
		
		task_board.lock_task();
		
		for player : Player in player_list:
			if len(player.current_task) > 0:
				var data : Dictionary = {
					action = "load_game",
				}
				var json : String = JSON.stringify(data);
				print("Sent ", json);
				player.peer_connection.put_packet(json.to_utf8_buffer());
		
	elif current_timer_type == COLONY.TIMER.DAILY_MEETING:
		current_timer_type = COLONY.TIMER.WORKING;
		timer_node.wait_time = max_work_time;
		
		for player: Player in player_list:
			if len(player.current_task) > 0:
				var data : Dictionary = {
					action = "load_game",
				}
				var json : String = JSON.stringify(data);
				print("Sent ", json);
				player.peer_connection.put_packet(json.to_utf8_buffer());
		
	elif current_timer_type == COLONY.TIMER.WORKING:
		
		timer_node.wait_time = max_meeting_time;
		
		
		if current_day < max_day_per_sprint && current_sprint < max_sprint_per_phase:
			current_timer_type = COLONY.TIMER.DAILY_MEETING;
			random_emergency_task();
			
		elif current_day == max_day_per_sprint && current_sprint < max_sprint_per_phase:
			current_timer_type = COLONY.TIMER.DAILY_MEETING;
			
			# Need tasks to fail.
			
			task_board.clear_unfinished_task();
			
			random_emergency_task();
			
			energy = max_energy;
			
			current_day = 0;
			current_sprint += 1;
			
		elif current_sprint == max_sprint_per_phase && current_day == max_day_per_sprint:
			next_phase();
			current_day = 0;
			current_sprint = 1;
			
		
		var data : Dictionary = {
			action = "stop_game"
		};
		
		var json : String = JSON.stringify(data);
		
		cam.run_cycle();
		
		network_manager.broadcast_message(json);
		
		current_day += 1;
		
	elif current_timer_type == COLONY.TIMER.RETROSPECTIVE:
		current_timer_type = COLONY.TIMER.SPRINT_PLANNING;
		
	timer_node.start();


func open_task_board():
	task_board.visible = true;
	
func close_task_board():
	task_board.visible = false;

func end_game():
	
	end_screen.show();
	
	task_board.hide();
	status_panel.hide();
	time_panel.hide();
	timer_panel.hide();
	energy_panel.hide();
	task_button.hide();
	
	timer_node.stop();
	
	for card in player_card_list:
		card.hide();
	
	# Give Stars
	var stars_label: Label = end_screen.get_child(0);
	var x_mark: String = "❌";
	var stars: PackedStringArray = ["😔", "😐", "🙂", "😄", "🤩"];
	
	
	if vic_score <= 0:
		# 0 star
		stars_label.text = x_mark.repeat(5);
		
	elif vic_score >= 0 && vic_score <= 200:
		# 1 star, score: 0 - 200
		stars_label.text = stars[0] + x_mark.repeat(4);
	
	elif vic_score >= 201 && vic_score <= 400:
		# 2 star, score: 200 - 400
		stars_label.text = stars[0] + stars[1] + x_mark.repeat(3);
		
	elif vic_score >= 401 && vic_score <= 600:
		# 3 star, score: 400 - 600
		stars_label.text = stars[0] + stars[1] + stars[2] + x_mark.repeat(2);
		
	elif vic_score >= 601 && vic_score <= 800:
		# 4 star, score: 600 - 800
		stars_label.text = stars[0] + stars[1] + stars[2] + stars[3] + x_mark;
	
	elif vic_score >= 800:
		# 5 star, score 800
		stars_label.text = stars[0] + stars[1] + stars[2] + stars[3] + stars[4];
	
	var total_score_label: Label = end_screen.get_child(2).get_child(0);
	var categories_score_label: Label = end_screen.get_child(3).get_child(0);
	
	total_score_label.text = str(vic_score);
	
	categories_score_label.text = "Security: %d x%.1f = %.2f\nSurvivability: %d x%.1f = %.2f\nDevelopement: %d x%.1f = %.2f" % [vic_sec, vic_coeff_a, vic_sec * vic_coeff_a, vic_sur, vic_coeff_b, vic_sur * vic_coeff_b, vic_dev, vic_coeff_c, vic_dev * vic_coeff_c];
