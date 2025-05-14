class_name Sky_control extends Camera3D

var go_night: bool = false;
var go_day: bool = false;

var cycle: bool = false;

var is_night: bool = false;
var is_day: bool = true;

var on_going: bool = false;

@export var directional_light: DirectionalLight3D;

var start_color: Color = Color.LIGHT_SALMON;
var end_color: Color = Color.DEEP_SKY_BLUE;

var light_multiplier: float = 0;

signal day();
signal night();

func run_cycle() -> void:
	cycle = true;
	
	set_night();

func set_day() -> void:
	light_multiplier = 0;
	
	if on_going:
		printerr("Can't set time, waiting for animation to ends.");
		return;
	
	go_day = true;
	go_night = false;
	on_going = true;
	
func set_night() -> void:
	light_multiplier = 0;
	
	if on_going:
		printerr("Can't set time, waiting for animation to ends.");
		return;
	
	go_night = true;
	go_day = false;
	on_going = true;

func _process(delta):
	if go_night:
		
		light_multiplier += delta;
		
		self.environment.background_energy_multiplier = lerpf(1, .1, light_multiplier);
		directional_light.light_energy = lerpf(1, .1, light_multiplier);
		directional_light.light_color = start_color.lerp(end_color, light_multiplier);
		
		if light_multiplier >= 1:
			night.emit();
			on_going = false;
			go_night = false;
			is_night = true;
			is_day = false;
			
			if cycle:
				set_day();
				cycle = false;
		
	if go_day:
		
		light_multiplier += delta;
		
		self.environment.background_energy_multiplier = lerpf(.1, 1, light_multiplier);
		
		directional_light.light_energy = lerpf(1, .1, light_multiplier);
		directional_light.light_color = end_color.lerp(start_color, light_multiplier);
		
		
		if light_multiplier >= 1:
			day.emit();
			is_day = true;
			is_night = false;
			on_going = false;
			go_day = false;
