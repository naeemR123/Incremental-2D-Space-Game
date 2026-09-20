extends HBoxContainer

@export var tab_container : TabContainer


func _ready() -> void:
	for i in get_child_count():
		var index = i # per button
		get_child(i).pressed.connect(func(): tab_container.current_tab = index)
