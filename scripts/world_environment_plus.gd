
extends WorldEnvironment
class_name WorldEnvironmentPlus

var motion_blur : CompositorEffectMotionBlur
@onready var canvas = $CanvasLayer/ColorRect
@onready var cam = $"../Character/Camera3D"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for effect in compositor.compositor_effects:
		if effect is CompositorEffectMotionBlur:
			motion_blur = effect
	
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if motion_blur:
		canvas.material.set_shader_parameter("prev_velocity_texture",canvas.material.get("shader_parameters/velocity_texture"))
		canvas.material.set_shader_parameter("velocity_texture",motion_blur.result)
		canvas.material.set_shader_parameter("depth_texture",motion_blur.result2)
		canvas.material.set_shader_parameter("colour_texture",motion_blur.result3)
		canvas.material.set_shader_parameter("INV_PROJECTION_MATRIX", cam.get_camera_projection().inverse())
	pass
