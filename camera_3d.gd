extends Camera3D

@export var marker : Marker3D
var mouse_sensitivity = 0.5

@onready var char = $".."

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	self.global_position = marker.global_position
	self.global_rotation = marker.global_rotation

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		marker.rotate_x(deg_to_rad(event.relative.y * mouse_sensitivity * -1))
		char.rotate_y(deg_to_rad(event.relative.x * mouse_sensitivity * -1))
		
		var camera_rot = self.rotation
		camera_rot.x = clamp(camera_rot.x, -0.5*PI, 0.5*PI)
		self.rotation = camera_rot
