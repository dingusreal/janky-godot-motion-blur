extends MeshInstance3D

@onready var offset = self.global_position
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	self.global_position.x = offset.x+sin(Time.get_unix_time_from_system()*20.0) * 2.0
	self.global_position.y = offset.y+(sin(Time.get_unix_time_from_system()*8.0) * 1.0) + 1.0
