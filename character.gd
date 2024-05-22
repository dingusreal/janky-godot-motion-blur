extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const ACCELERATION = 0.1
const FRICTION = 0.25
const AIR_ACCELERATION = 0.5

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("mv_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("mv_left", "mv_right", "mv_up", "mv_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction and is_on_floor:
		velocity.x = move_toward(velocity.x, direction.x*SPEED, FRICTION)
		velocity.z = move_toward(velocity.z, direction.z*SPEED, FRICTION)
	elif direction:
		velocity.x = move_toward(velocity.x, direction.x*SPEED, AIR_ACCELERATION)
		velocity.z = move_toward(velocity.z, direction.z*SPEED, AIR_ACCELERATION)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, FRICTION)
		velocity.z = move_toward(velocity.z, 0, FRICTION)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION/AIR_ACCELERATION)
		velocity.z = move_toward(velocity.z, 0, FRICTION/AIR_ACCELERATION)

	move_and_slide()
