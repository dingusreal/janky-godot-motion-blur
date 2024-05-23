extends MeshInstance3D

func _physics_process(delta: float) -> void:
	self.global_rotation_degrees.y += delta * 360 * 4.0
