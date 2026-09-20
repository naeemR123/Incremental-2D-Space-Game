extends Node




var run : Dictionary = {}		# Resets via game_reset()
var lifetime : Dictionary = {}	# Survives reset | Saves to disk



func _ready() -> void:
	WaveManager.wave_complete.connect(debug_print)

# Adds to counter_id, Defaults at 0.0
func increment(counter_id: String, amount: float = 1.0) -> void:
	run[counter_id] = run.get(counter_id, 0.0) + amount
	lifetime[counter_id] = lifetime.get(counter_id, 0.0) + amount

# Stores personal best | i.e. highest wave reached
func record_max(counter_id: String, value: float) -> void:
	if value > run.get(counter_id, 0.0):
		run[counter_id] = value
	if value > lifetime.get(counter_id, 0.0):
		lifetime[counter_id] = value

# Reads run counter | Returns defaults if nothing
func get_run(counter_id: String) -> float:
	return run.get(counter_id, 0.0)


# Reads lifetime counter | Returns defaults if nothing
func get_lifetime(counter_id: String) -> float:
	return lifetime.get(counter_id, 0.0)

# Clears run's data (lifetime preserved) | Called via game_reset()
func reset_run() -> void:
	run.clear()
	print(" | RUN STATS RESET | ")

# [DEBUGGING]
func debug_print() -> void:
	print_rich(" [color=yellow][b]STATS[/b][/color] RUN: %s" % run)
	print_rich(" [color=yellow][b]STATS[/b][/color] LIFETIME: %s" % lifetime)
