extends MeshInstance3D

func _process(delta: float) -> void:
	self.global_rotation_degrees.y += delta * 720.0
