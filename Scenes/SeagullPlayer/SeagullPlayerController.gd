extends CharacterBody3D

@export var acceleration: float = 2 # how quickly the plane can change speed
@export var throttleSpeed: float = 2 # how quickly the throttle can change
@export var maxPitchSpeed: float = PI/2 # how quickly the plane can pitch, in radians per second
@export var maxRollSpeed: float = PI
@export var maxYawSpeed: float = PI/2
@export var minSpeed: float = 0.1
@export var maxSpeed: float = 0.1
@export var mouseSensitivity: float = 100
@export var respawn_position: Vector3 = Vector3(0, 102.173, 0) 
@export var respawn_delay: float = 2.0 


var targetSpeed: float = 0
var speed: float = 0

var pitch: float = 0
var roll: float = 0
var yaw: float = 0

var continuedMousePos = Vector2.ZERO # position of the mouse, not including the fact we reset it's position every frame 
var lerpedMousePos = Vector2.ZERO # we lerp this towards the actual mouse position, then subtract the last lerped mouse pos to work out the change in position, which we use to determine the amount to pitch or roll by
var lastLerpedMousePos = Vector2.ZERO
var mouseMotion = Vector2.ZERO
var throttle = 0

var can_grab = false
var grabbable_student : Node3D # who can we nick chips from?
signal hit

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority(): return
	$Camera3D.current = true
	
	
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
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

func getScreenSpaceMousePos():
	var absPos = get_viewport().get_mouse_position()
	var screenSize = Vector2(get_viewport().size.x, get_viewport().size.y)
	
	return absPos / screenSize


func getMouseMotion():
	# every frame we reset the position of the mouse to 0.5, 0.5, so the difference between this and the actual position is the motion of the mouse
	var mousePos = getScreenSpaceMousePos()
	continuedMousePos += mousePos - Vector2(0.5, 0.5) #Vector2(stepify(mousePos.x, 0.1), stepify(mousePos.y, 0.1)) - Vector2(0.5, 0.5)
	lastLerpedMousePos = lerpedMousePos
	lerpedMousePos = lerp(lastLerpedMousePos, continuedMousePos, 0.05)
	mouseMotion = lerpedMousePos - lastLerpedMousePos

#	print(Vector2(floor(get_viewport().size.x * 0.5), floor(get_viewport().size.y * 0.5)))
#	print(get_viewport().get_mouse_position())
#	print("---")

	get_viewport().warp_mouse(Vector2(floor(get_viewport().size.x * 0.5), floor(get_viewport().size.y * 0.5)))#floor(get_viewport().size * 0.5))

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	if Input.is_action_pressed("throttle_up") and throttle <= 1.0:
		throttle += throttleSpeed * delta
	elif Input.is_action_pressed("throttle_down") and throttle >= 0.0:
		throttle -= throttleSpeed * delta

	getMouseMotion()

	pitch = mouseMotion.y * delta * maxPitchSpeed * mouseSensitivity
		
	#roll = lerp(roll, Input.get_axis("roll_left", "roll_right") * delta * maxRollSpeed, 0.1)
	roll = mouseMotion.x * delta * maxRollSpeed * mouseSensitivity

	transform.basis = transform.basis.rotated(transform.basis.x.normalized(), pitch)
	transform.basis = transform.basis.rotated(transform.basis.y.normalized(), yaw)
	transform.basis = transform.basis.rotated(transform.basis.z.normalized(), roll)

	throttle = clampf(throttle, 0.0, 1.0)

	targetSpeed = (throttle * (maxSpeed - minSpeed)) + minSpeed
	speed = lerp(speed, targetSpeed, acceleration * delta)

	velocity = transform.basis.z * speed
	move_and_collide(velocity)
	
	var collision = move_and_collide(velocity)
	if collision:
		die()

func die():
	hit.emit()
	
	await get_tree().create_timer(respawn_delay).timeout

	respawn()
	
func respawn():
	await get_tree().create_timer(1).timeout
	position = respawn_position
	# get_tree().reload_current_scene()

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
