extends KinematicBody2D
export var speed := 500
var gravity := Vector2.DOWN * 300
var jump_force := 0
var can_jump := true


func _unhandled_input(event):
	if event.is_action_pressed("ui_select") and can_jump:
		self.can_jump = false
		$Tween.interpolate_property(self, "jump_force", 500, 600, 0.25)
		$Tween.start()
		yield($Tween, "tween_completed")
		$Tween.interpolate_property(self, "jump_force", 100, 0, 0.1)
		$Tween.start()
		yield($Tween, "tween_completed")
		self.can_jump = true


func _physics_process(delta):
	var x = int(Input.get_action_strength("ui_right")) - int(Input.get_action_strength("ui_left"))
	var direction = Vector2(x, 0)
	var jump := Vector2.UP * jump_force

	self.move_and_slide(direction * speed + gravity + jump)
