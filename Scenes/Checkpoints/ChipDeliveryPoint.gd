extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_area_3d_body_entered(body: Node3D) -> void:
	if not body.is_in_group("student"):
		return
		
	if body.has_chips:
		# the student decides whether or not it has the authority to call the server
		body.deliver_chips()
