extends CharacterBody3D

@onready var minimap_camera = $MinimapSubViewport/MinimapCamera
@onready var minimap_subviewport = $MinimapSubViewport
@onready var minimap_rect = $CanvasLayer/MinimapRect

const SPEED = 20.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.05

var shot_cooldown = 0.0
var stuck = false

var username: String = ""

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

	if not is_multiplayer_authority(): 
		$CanvasLayer.visible = false
		return
		
	$Camera3D.current = true
	setup_minimap()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func setup_minimap():
	minimap_subviewport.world_3d = get_world_3d()
	minimap_camera.current = true
	minimap_camera.rotate(Vector3(1,0,0),deg_to_rad(-90))
	minimap_subviewport.size = Vector2(500, 500)
	minimap_rect.texture = minimap_subviewport.get_texture()
	
	var player_dot = ColorRect.new()
	player_dot.color = Color(1,0,0)
	player_dot.size = Vector2(10,10)
	minimap_rect.add_child(player_dot)
	player_dot.position = Vector2(250,250)
	

	
func _input(event):
	if not is_multiplayer_authority(): return
	
	# turn camera with mouse
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		self.rotate_y(deg_to_rad(event.relative.x * MOUSE_SENSITIVITY * -1))
		
		$Camera3D.rotate_x(deg_to_rad(event.relative.y * MOUSE_SENSITIVITY * -1))
		
	if event.is_action_pressed("shoot") and shot_cooldown == 0.0:
		shot_cooldown = 0.5
		$GunAnimator.play("Shoot")
		var collider = $Camera3D/RayCast3D.get_collider()
		# boil
		if collider:
			if collider.is_in_group("seagull_colliders"):
				collider.get_stunned()
			

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	shot_cooldown = max(0.0, shot_cooldown - delta)
	
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
		
	if stuck:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()
	minimap_camera.global_transform.origin = global_transform.origin + Vector3(0, 100, 0)

	
func deliver_chips():
	if not is_multiplayer_authority(): 
		print(" i am not the uathority")
		return
	has_chips = false
	print("i just set chips to false and announced chips delivered. i am : %s" % [String(name)])
	GlobalHandler.announce_chips_delivered()
	
@rpc("any_peer","reliable")
func get_chips_stolen():
	if is_multiplayer_authority():
		has_chips = false
		GlobalHandler.announce_chips_stolen()
	else:
		var client_id = int(String(name))
		rpc_id(client_id,"get_chips_stolen")
	
@rpc("any_peer", "reliable")
func get_stuck():
	if !is_multiplayer_authority():
		rpc_id(int(name), "get_stuck")
	else:
		if stuck: return
		print("stuck!")
		stuck = true
		await get_tree().create_timer(10).timeout
		stuck = false

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
