extends Area2D

@export var backlog_highlight: Panel;
@export var todo_highlight: Panel;

var allow_highlight: bool = false;

func on_task_enter(task: Node2D):
	
	if self.name.contains("backlog"):
		task.column = 0;
			
		if allow_highlight:
			backlog_highlight.visible = true;
			todo_highlight.visible = false;
			
	if self.name.contains("todo"):
		task.column = 1;
			
		if allow_highlight:
			todo_highlight.visible = true;
			backlog_highlight.visible = false;
	if self.name.contains("in-progress"):
		task.column = 2;
	if self.name.contains("done"):
		task.column = 3;
	
			
func on_task_leaves(task : Node2D):
	if self.name.contains("backlog"):
		backlog_highlight.visible = false;
	if self.name.contains("todo"):
		todo_highlight.visible = false;
