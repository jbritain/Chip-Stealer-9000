# GameHUD.gd
extends CanvasLayer

@onready var score_label = $PanelContainer/HBoxContainer/Label

func _ready():
	show()
	update_score_display(GlobalHandler.walking_score, GlobalHandler.seagull_score)

func update_score_display(walking_score, seagull_score):
	score_label.text = "Walking: %d | Seagulls: %d" % [walking_score, seagull_score]
