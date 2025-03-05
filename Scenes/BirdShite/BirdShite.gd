extends CharacterBody3D

var time_alive = 0.0

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	
	velocity.y -= delta * 0.4
	var collision = move_and_collide(velocity)
	
	if collision:
		$blob.visible = false
		$splatter.visible = true
	else:
		$blob.visible = true
		$splatter.visible = false

	time_alive += delta
	
	if time_alive >= 30.0:
		queue_free()
		
		
func _on_area_3d_body_entered(body: Node3D) -> void:
	if !is_multiplayer_authority(): return
	if body.is_in_group("student"):
		body.get_stuck()
