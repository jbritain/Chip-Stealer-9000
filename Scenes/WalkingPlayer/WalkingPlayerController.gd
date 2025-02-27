extends CharacterBody3D

#@export var camera: Camera3D

const SPEED = 20.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.05

var has_chips = true

func _ready():
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	self.add_to_group("student")
#
#func _input(event):
	## turn camera with mouse
	#if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		#self.rotate_y(deg_to_rad(event.relative.x * MOUSE_SENSITIVITY * -1))
		#
		#camera.rotate_x(deg_to_rad(event.relative.y * MOUSE_SENSITIVITY * -1))
#
	#if event.is_action_pressed("quit"):
		#get_tree().quit()
##
#func _physics_process(delta: float) -> void:
	## Add the gravity.
	#if not is_on_floor():
		#velocity += get_gravity() * delta
#
	## Handle jump.
	#if Input.is_action_just_pressed("jump") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
#
	#var input_dir := Input.get_vector("walk_left", "walk_right", "walk_forward", "walk_back")
	#var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#if direction:
		#velocity.x = direction.x * SPEED
		#velocity.z = direction.z * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
		#velocity.z = move_toward(velocity.z, 0, SPEED)
#
	#move_and_slide()
