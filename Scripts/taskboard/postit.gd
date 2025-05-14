extends CharacterBody2D

var draggingDistance
var dir
var dragging
var newPosition = Vector2()

var mouse_in = false

var original_position: Vector2;

const BOARD_COLUMN: Dictionary = {
	BACKLOG = 0,
	TODO = 1,
	INPROGRESS = 2,
	DONE = 3
}

signal release_card(this: Node2D);
signal start_drag(this: Node2D);
	
# Code from https://www.youtube.com/watch?v=GfGpXfbLVBA
func _input(event):
	if event is InputEventMouseButton && !locked:
		if event.is_pressed() && mouse_in:
			draggingDistance = position.distance_to(get_viewport().get_mouse_position())
			dir = (get_viewport().get_mouse_position() - position).normalized()
			dragging = true
			newPosition = get_viewport().get_mouse_position() - draggingDistance * dir
			
			start_drag.emit(self);
		
		else:
			dragging = false
			
		if !event.is_pressed() and mouse_in:
			release_card.emit(self);
			
	elif event is InputEventMouseMotion:
		if dragging:
			newPosition = get_viewport().get_mouse_position() - draggingDistance * dir

func _physics_process(_delta):
	if dragging:
		velocity = (newPosition - position) * Vector2(30, 30)
		move_and_slide()
	
 # Set these two functions through the Area2D Signals!!
func mouse_entered():
	mouse_in = true
	(self.get_child(0) as ColorRect).size = Vector2(184, 216);
	
	if color == -1:
		if !isEmergency:
			(self.get_child(0) as ColorRect).color = Color.html("#ffbe76");
		else:
			(self.get_child(0) as ColorRect).color = Color.html("#EA2027");
	else:
		(self.get_child(0) as ColorRect).color = (self.get_child(0) as ColorRect).color.darkened(.3);
		

	description.show();
	move.emit(self, -1);

func mouse_exited():
	mouse_in = false
	description.hide();
	(self.get_child(0) as ColorRect).size = Vector2(184, 40);
	
	if color == -1:
		if !isEmergency:
			(self.get_child(0) as ColorRect).color = Color.html("#ffffc7");
		else:
			(self.get_child(0) as ColorRect).color = Color.html("#EA2027");
	else:
		if !isEmergency:
			match color:
				0: (self.get_child(0) as ColorRect).color = GAME_COLOR.COLOR.BLUE;
				1: (self.get_child(0) as ColorRect).color = GAME_COLOR.COLOR.GRAY;
				2: (self.get_child(0) as ColorRect).color = GAME_COLOR.COLOR.GREEN;
				3: (self.get_child(0) as ColorRect).color = GAME_COLOR.COLOR.ORANGE;
				4: (self.get_child(0) as ColorRect).color = GAME_COLOR.COLOR.PINK;
				5: (self.get_child(0) as ColorRect).color = GAME_COLOR.COLOR.RED;
				6: (self.get_child(0) as ColorRect).color = GAME_COLOR.COLOR.VIOLET;
				7: (self.get_child(0) as ColorRect).color = GAME_COLOR.COLOR.YELLOW;
		else:
			(self.get_child(0) as ColorRect).color = Color.html("#EA2027");
			
	move.emit(self, current_node_index);
	
func return_to_original_pos():
	self.position = original_position;
	
func _ready():
	original_position = self.position;
	current_node_index = self.get_index();
	(self.get_child(1) as Label).text = task.task_name;
	description = self.get_child(2);
	description.hide();
	(self.get_child(5) as Sprite2D).hide();
	if !isEmergency:
		description.text = """Effects			Cost: %d
%s%s%s%s%s%s""" % [task.task_energy_consumption, 
"- Morale\n" if task.task_effect.morale < 0 else "+ Morale\n" if task.task_effect.morale > 0 else "",
"- Integrity\n" if task.task_effect.integrity < 0 else "+ Integrity\n" if task.task_effect.integrity > 0 else "",
"- Health\n" if task.task_effect.health < 0 else "+ Health\n" if task.task_effect.health > 0 else "",
"- Environment\n" if task.task_effect.environment < 0 else "+ Environment\n" if task.task_effect.environment > 0 else "",
"- Threat\n" if task.task_effect.threat < 0 else "+ Threat\n" if task.task_effect.threat > 0 else "",
"-%d Energy\n" % task.task_effect.max_energy_mod if task.task_effect.max_energy_mod < 0 else "+%d Energy\n" % task.task_effect.max_energy_mod if task.task_effect.max_energy_mod > 0 else ""];
	else:
		(self.get_child(0) as ColorRect).color = Color.html("#EA2027");
		(self.get_child(5) as Sprite2D).show();
		description.text = """Cost: %d\nFailure Effects
%s%s%s%s%s%s""" % [task.task_energy_consumption, 
"- Morale\n" if task.task_effect.morale < 0 else "+ Morale\n" if task.task_effect.morale > 0 else "",
"- Integrity\n" if task.task_effect.integrity < 0 else "+ Integrity\n" if task.task_effect.integrity > 0 else "",
"- Health\n" if task.task_effect.health < 0 else "+ Health\n" if task.task_effect.health > 0 else "",
"- Environment\n" if task.task_effect.environment < 0 else "+ Environment\n" if task.task_effect.environment > 0 else "",
"- Threat\n" if task.task_effect.threat < 0 else "+ Threat\n" if task.task_effect.threat > 0 else "",
"-%d Energy\n" % task.task_effect.max_energy_mod if task.task_effect.max_energy_mod < 0 else "+%d Energy\n" % task.task_effect.max_energy_mod if task.task_effect.max_energy_mod > 0 else ""];		
	
var task: Task;
var column : int = 0;
var assigned_to_id : String = "";
var color: int = -1;

var energy_deducted: bool = false;
var energy_added: bool = true;

var current_node_index: int;

var description: RichTextLabel;

var locked: bool = false;

var isEmergency : bool = false;

signal move(task_node: Node, target: int);
