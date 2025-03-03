extends CharacterBody3D

#@export var camera: Camera3D

const SPEED = 20.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.05

@export var has_chips = false:
	set(value):
		if has_chips != value:
			if value == false:
				print("lost me chips!",name)	
			else:
				print("got some chips!",name)
			
			has_chips = value
			
func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	self.add_to_group("student")

	if not is_multiplayer_authority(): return
	
	$Camera3D.current = true
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if not is_multiplayer_authority(): return
	
	# turn camera with mouse
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		self.rotate_y(deg_to_rad(event.relative.x * MOUSE_SENSITIVITY * -1))
		
		$Camera3D.rotate_x(deg_to_rad(event.relative.y * MOUSE_SENSITIVITY * -1))

	if event.is_action_pressed("quit"):
		get_tree().quit()

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("walk_left", "walk_right", "walk_forward", "walk_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
func deliver_chips():
	if not is_multiplayer_authority(): return
	GlobalHandler.announce_chips_delivered()
	has_chips = false
	
@rpc("any_peer","reliable")
func get_chips_stolen():
	if is_multiplayer_authority():
		has_chips = false
		GlobalHandler.announce_chips_stolen()
	else:
		var client_id = int(String(name))
		rpc_id(client_id,"get_chips_stolen")
	
	

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
