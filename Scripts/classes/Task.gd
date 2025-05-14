class_name Task

var task_id: int;
var task_name: String;
var task_effect: Dictionary;
var task_energy_consumption: int;
var task_game : Array;
var task_difficulty: int;
var task_completed: bool = false;
var task_description: String = "";
	
static var DIFFICULTY : Dictionary = {
	EASY = 0,
	MEDIUM = 1,
	HARD = 2,
	VERY_HARD = 3
}
