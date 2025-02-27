extends CharacterBody3D

@export var acceleration: float = 2 # how quickly the plane can change speed
@export var throttleSpeed: float = 2 # how quickly the throttle can change
@export var maxPitchSpeed: float = PI/2 # how quickly the plane can pitch, in radians per second
@export var maxRollSpeed: float = PI
@export var maxYawSpeed: float = PI/2
@export var minSpeed: float = 1
@export var maxSpeed: float = 5
@export var mouseSensitivity: float = 100

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

signal hit

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _input(event):
	if event.is_action_pressed("quit"):
		get_tree().quit()

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

func die():
	hit.emit()
	queue_free()

func _on_mob_detector_body_entered(body: Node3D) -> void:
	die()
