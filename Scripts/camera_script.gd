extends Camera3D

@export var ray_length : int = 100;

func ray_cast_from_camera() -> Dictionary:
	
		#Code from https://forum.godotengine.org/t/godot-4-how-to-cast-a-ray-from-mouse-position-towards-camera-orientation-in-3d/5280/2
		var mouse_pos : Vector2 = get_viewport().get_mouse_position()
		var from = self.project_ray_origin(mouse_pos);
		var to = from + self.project_ray_normal(mouse_pos) * ray_length;
		
		var space = get_world_3d().direct_space_state;
		var ray_query = PhysicsRayQueryParameters3D.new();
		ray_query.from = from;
		ray_query.to = to;
		ray_query.collide_with_bodies = true;
		ray_query.hit_back_faces = false;
		
		var raycast_result = space.intersect_ray(ray_query);
		
		return raycast_result;

func _input(event):
	
	#on-click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		ray_cast_from_camera();
