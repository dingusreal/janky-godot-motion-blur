extends CompositorEffect
class_name CompositorEffectMotionBlur

var rd : RenderingDevice
var pipeline : RID
var shader : RID

var texture_data
var output_image

var output_tex = ImageTexture.new()

var nearest_sampler
var linear_sampler

var context : StringName = "MotionBlur"
var texture : StringName = "output_image"
var texture2 : StringName = "output_image_2"
var texture3 : StringName = "output_image_3"

var result : ImageTexture
var result2 : ImageTexture
var result3 : ImageTexture

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# When this is called it should be safe to clean up our shader.
		if nearest_sampler.is_valid():
			rd.free_rid(nearest_sampler)
		if linear_sampler.is_valid():
			rd.free_rid(linear_sampler)
		if shader.is_valid():
			rd.free_rid(shader)

func _init() -> void:
	needs_motion_vectors = true
	effect_callback_type = CompositorEffect.EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	RenderingServer.call_on_render_thread(_initialize_compute)

func _initialize_compute():
	rd = RenderingServer.get_rendering_device()
	
	var sampler_state : RDSamplerState = RDSamplerState.new()
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	nearest_sampler = rd.sampler_create(sampler_state)

	sampler_state = RDSamplerState.new()
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	linear_sampler = rd.sampler_create(sampler_state)
	
	
	var src = load("res://shaders/post_process/motion_blur.glsl")
	var shader_spirv = src.get_spirv()
	
	var err = shader_spirv.get_stage_compile_error(RenderingDevice.SHADER_STAGE_COMPUTE)
	if err: push_error( err )
	
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)

func get_image_uniform(image : RID, binding : int = 0) -> RDUniform:
	var uniform : RDUniform = RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = binding
	uniform.add_id(image)

	return uniform

func get_sampler_uniform(image : RID, binding : int = 0, linear : bool = true) -> RDUniform:
	var uniform : RDUniform = RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	uniform.binding = binding
	if linear:
		uniform.add_id(linear_sampler)
	else:
		uniform.add_id(nearest_sampler)
	uniform.add_id(image)

	return uniform

func _render_callback(effect_callback_type: int, render_data: RenderData) -> void:
	var render_scene_buffers : RenderSceneBuffersRD = render_data.get_render_scene_buffers()
	var render_scene_data : RenderSceneDataRD = render_data.get_render_scene_data()
	if render_scene_buffers and render_scene_data:
		var scale = ProjectSettings.get_setting("rendering/scaling_3d/scale")
		var window_size = DisplayServer.window_get_size(0)
		var render_size : Vector2 = render_scene_buffers.get_internal_size()
		if render_size.length() == 0.0:
			return
			
		if render_scene_buffers.has_texture(context, texture):
			var tf : RDTextureFormat = render_scene_buffers.get_texture_format(context, texture)
			if tf.width != render_size.x or tf.height != render_size.y:
				print("cleared context")
				# This will clear all textures for this viewport under this context
				render_scene_buffers.clear_context(context)
		if render_scene_buffers.has_texture(context, texture2):
			var tf : RDTextureFormat = render_scene_buffers.get_texture_format(context, texture2)
			if tf.width != render_size.x or tf.height != render_size.y:
				print("cleared context")
				# This will clear all textures for this viewport under this context
				render_scene_buffers.clear_context(context)
		if render_scene_buffers.has_texture(context, texture3):
			var tf : RDTextureFormat = render_scene_buffers.get_texture_format(context, texture3)
			if tf.width != render_size.x or tf.height != render_size.y:
				print("cleared context")
				# This will clear all textures for this viewport under this context
				render_scene_buffers.clear_context(context)
					
		if !render_scene_buffers.has_texture(context, texture):
			print("created texture")
			var usage_bits : int = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
			render_scene_buffers.create_texture(context, texture, RenderingDevice.DATA_FORMAT_R8G8_UNORM, usage_bits, RenderingDevice.TEXTURE_SAMPLES_1, render_size, 1, 1, true)
		if !render_scene_buffers.has_texture(context, texture2):
			print("created texture")
			var usage_bits : int = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
			render_scene_buffers.create_texture(context, texture2, RenderingDevice.DATA_FORMAT_R8_UNORM, usage_bits, RenderingDevice.TEXTURE_SAMPLES_1, render_size, 1, 1, true)
		if !render_scene_buffers.has_texture(context, texture3):
			print("created texture")
			var usage_bits : int = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
			render_scene_buffers.create_texture(context, texture3, RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT, usage_bits, RenderingDevice.TEXTURE_SAMPLES_1, render_size, 1, 1, true)
		rd.draw_command_begin_label("Motion Blur", Color(1.0, 1.0, 1.0, 1.0))
		
		var color_tex = render_scene_buffers.get_color_layer(0)
		var depth_tex = render_scene_buffers.get_depth_layer(0)
		var vel_tex = render_scene_buffers.get_velocity_layer(0)
		
		var clr_uniform = get_sampler_uniform(color_tex,0)
		var dep_uniform = get_sampler_uniform(depth_tex,1)
		var vel_uniform = get_sampler_uniform(vel_tex,2)
		
		var input_uniform_set = UniformSetCacheRD.get_cache(shader, 0, [ clr_uniform, dep_uniform, vel_uniform ] )
		
		var texture_image = render_scene_buffers.get_texture(context, texture)
		var texture_image_2 = render_scene_buffers.get_texture(context, texture2)
		var texture_image_3 = render_scene_buffers.get_texture(context, texture3)
		var img_uniform = get_image_uniform(texture_image,0)
		var img_uniform_2 = get_image_uniform(texture_image_2, 1)
		var img_uniform_3 = get_image_uniform(texture_image_3, 2)
		var output_uniform_set = UniformSetCacheRD.get_cache(shader, 1, [img_uniform, img_uniform_2, img_uniform_3])
		
		var x_groups = (render_size.x - 1) / 8 + 1
		var y_groups = (render_size.y - 1) / 8 + 1
		
		var compute_list := rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
		rd.compute_list_bind_uniform_set(compute_list, input_uniform_set, 0)
		rd.compute_list_bind_uniform_set(compute_list, output_uniform_set, 1)
		rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
		rd.compute_list_end()
		
		rd.draw_command_end_label()
		
		rd.submit()
		
		rd.sync()
		
		
		
		var img = rd.texture_get_data(texture_image,0)
		var img2 = rd.texture_get_data(texture_image_2,0)
		var img3 = rd.texture_get_data(texture_image_3,0)
		var dingus = Image.create_from_data(render_size.x,render_size.y,false,Image.FORMAT_RG8,img)
		var dingus2 = Image.create_from_data(render_size.x,render_size.y,false,Image.FORMAT_R8,img2)
		var dingus3 = Image.create_from_data(render_size.x,render_size.y,false,Image.FORMAT_RGBAF,img3)
		result = ImageTexture.create_from_image(dingus)
		result2 = ImageTexture.create_from_image(dingus2)
		result3 = ImageTexture.create_from_image(dingus3)
