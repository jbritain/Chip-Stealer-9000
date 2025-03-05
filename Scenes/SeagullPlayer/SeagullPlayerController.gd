extends CharacterBody3D

@export var acceleration: float = 2 # how quickly the plane can change speed
@export var throttleSpeed: float = 2 # how quickly the throttle can change
@export var pitchSpeed: float = PI/2 # how quickly the plane can pitch, in radians per second
@export var rollSpeed: float = PI
@export var yawSpeed: float = PI/2
@export var minSpeed: float = 0.0
@export var maxSpeed: float = 0.1
@export var respawn_position: Vector3 = Vector3(0, 102.173, 0) 
@export var respawn_delay: float = 10.0 
@export var cameraLerpSpeed: float = 10.0
@export var stunned = false

var mouse_position_since_clicked = Vector2.ZERO

var targetSpeed: float = 0
var speed: float = 0

var pitch: float = 0
var roll: float = 0
var yaw: float = 0

var throttle = 0

var can_grab = false
var grabbable_student : Node3D # who can we nick chips from?
signal hit


func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority(): return
	$Camera3D.current = true
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	self.add_to_group("seagull")

func _input(event):
	if not is_multiplayer_authority(): return
	if event.is_action_pressed("quit"):
		get_tree().quit()
	if event.is_action_pressed("jump") and can_grab:
		print("gotcha")
		# in this case we decide if we have the authority to steal the chips, but the student makes the call since it's their value being modified
		grabbable_student.get_chips_stolen()
		
		self.can_grab = false
		
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and Input.is_action_pressed("pan_camera"):
		mouse_position_since_clicked += event.relative / get_viewport().get_visible_rect().size
		mouse_position_since_clicked.x = clamp(mouse_position_since_clicked.x, -PI, PI)
		mouse_position_since_clicked.y = clamp(mouse_position_since_clicked.y, -PI * 0.48, PI * 0.48)
		print(mouse_position_since_clicked)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	transform.basis = transform.basis.rotated(transform.basis.x.normalized(), Input.get_axis("pitch_up", "pitch_down") * delta * pitchSpeed)


	transform.basis.rotated(transform.basis.y.normalized(), Input.get_axis("yaw_right", "yaw_left") * delta * yawSpeed)
	transform.basis = transform.basis.rotated(transform.basis.z.normalized(), Input.get_axis("roll_left", "roll_right") * delta * rollSpeed)

	if Input.is_action_pressed("throttle_up") and throttle <= 1.0:
		throttle += throttleSpeed * delta
	elif Input.is_action_pressed("throttle_down") and throttle >= 0.0:
		throttle -= throttleSpeed * delta
		
	throttle = clampf(throttle, 0.0, 1.0)

	targetSpeed = (throttle * (maxSpeed - minSpeed)) + minSpeed
	speed = lerp(speed, targetSpeed, acceleration * delta)

	if !stunned:
		velocity = transform.basis.z * speed
	else:
		if is_on_floor():
			velocity.y = max(velocity.y, 0.0) # reset gravity if on ground
		
		velocity.y -= 0.2 * delta # gravity
	move_and_collide(velocity)
	
	var camera_target_pos = global_position - (global_basis.z if !Input.is_action_pressed("pan_camera") else Vector3.ZERO)
	var camera_target_look_pos = global_position
	
	if Input.is_action_pressed("pan_camera"):
		$Camera3D.top_level = false
		$Camera3D.position = Vector3.ZERO
		$Camera3D.rotation = rotation
		$Camera3D.look_at(position + Vector3.DOWN + transform.basis.z * 0.01)
	else:
		$Camera3D.top_level = true
		mouse_position_since_clicked = Vector2.ZERO
		var actual_rotation = $Camera3D.global_rotation
		$Camera3D.look_at(camera_target_look_pos)
		var look_at_rotation = $Camera3D.global_rotation
		$Camera3D.global_rotation.x = lerp_angle(actual_rotation.x, look_at_rotation.x, 0.1)
		$Camera3D.global_rotation.y = lerp_angle(actual_rotation.y, look_at_rotation.y, 0.1)
		$Camera3D.global_rotation.z = lerp_angle(actual_rotation.z, look_at_rotation.z, 0.1)
		
		$Camera3D.global_position = lerp($Camera3D.global_position, camera_target_pos, cameraLerpSpeed * delta)

		
	if $Camera3D.global_position.distance_to(global_position) < 0.5:
		visible = false
	else:
		visible = true
	



	var collision = move_and_collide(velocity)
	if collision:
		get_stunned()


	
@rpc("any_peer", "reliable", "call_local")
func get_stunned():
	if stunned:
		return
	
	if !is_multiplayer_authority():
		rpc_id(int(name), "get_stunned")
		return
	print("I got stunned")
	stunned = true
	
	await get_tree().create_timer(respawn_delay).timeout
	
	print("I got up")
	stunned = false
	global_position.y += 100.0

#func _on_mob_detector_body_entered(body: Node3D) -> void:
	#if body != self:
		#die()
		
func _on_can_grab_chips(body: Node3D):
	if not is_multiplayer_authority(): return
	print("collison")
	if body.is_in_group("student") and body.has_chips:
		print("its a student and they have chips!")
		self.can_grab = true
		self.grabbable_student = body
		
		var timer = get_tree().create_timer(1.0)
		await timer.timeout
		self.can_grab = false
