#youtu.be/A3HLeyaBCq4
extends CharacterBody3D


var speed
const WALK_SPEED = 5.0
const SPEED_MULTIPLIER = 2.0
const SPRINT_SPEED = WALK_SPEED * SPEED_MULTIPLIER # 50 is very fun

const JUMP_VELOCITY = 6
const JUMP_MULTIPLIER = 1.3
const JUMP_MAX = 1000

const SENSITIVITY = 0.005

# head bob
const BOB_FREQ = 2.0
const BOB_AMPL = 0.08
var t_bob = 0.0

# FOV
const FOV_BASE = 75.0
const FOV_CHANGE = 1.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 2 # 9.8

@onready var head = $Head
@onready var camera = $Head/Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # Скрывает курсор мыши

func _unhandled_input(event): 
	if event is InputEventMouseMotion: # Мотание башкой
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY) # Нужно, чтобы камера вообще адекватно крутилась, кватернионы и все такое
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle Jump.
	if Input.is_action_pressed("jump") and is_on_floor():
		if speed == SPRINT_SPEED:
			velocity.y = JUMP_VELOCITY * JUMP_MULTIPLIER
		else:
			velocity.y = JUMP_VELOCITY
	if Input.is_action_pressed("sprint") and is_on_floor():
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta)
		velocity.z = lerp(velocity.z, direction.z * speed, delta)
	
	# Head bobbing
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = FOV_BASE + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMPL
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMPL
	return pos
