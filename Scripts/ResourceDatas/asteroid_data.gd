extends Resource
class_name AsteroidData

enum BehaviorType { DEFAULT, COMET, BOSS }

@export_category("Visuals")
@export var name : String
@export var sprite_textures : Array[Texture2D] = []
## Size scale: 1.5 = 1.5x scale
@export var scale_ratio : float = 1

@export_category("Base Stats")
## Base max health
@export var max_health : float
## Damage to planet on hit
@export var damage : float
## Pixels per second at wave 1. 
## [br]Spawn radius is [b]2120px[/b] [i](although check asteroid_spawner.radius to update)[/i] [br]
## ^ Means 96 = 22 seconds of travel from spawn to planet [b](radius/seconds = px/s)[/b]. [br]
## "max_speed" because there can be speed variance.
@export var max_speed : float
## Percentage of variance: 0.12 = up to 12% increase/decrease
@export var speed_variance : float = 0.12
@export var sprite_scale : float = 1.0

@export_category("Resistances")
## i.e. 'slow': 0.3 = 30% resistance to slow status effect
@export var resistances : Dictionary[String, float] = {}

@export_category("Spawning")
## Earliest wave this asteroid can start spawning
@export var min_wave : int
## How likely this asteroid is to spawn. Weighed against all asteroids available for this wave (based on min_wave). Higher = more likely
@export var spawn_weight : float 
## Chance for asteroid to be golden: 0.1 = 10% chance
@export var golden_spawn_chance : float = 0.05
@export_group("Spawn Weight Scaling")
## Spawn Weight at Weight Ramp End Wave. [br]Ex: -1 = no ramp, weight stays flat. 40 = Spawn Weight is 40 at the specified end wave
@export var spawn_weight_end : float = -1.0
## Wave weight scaling maxes out at. Spawn Weight End will apply at this value. [br]Ex: 100 = Spawn Weight will reach it's max at wave 100
@export var weight_ramp_end_wave : int = 100
## How fast scaling happens: < 1 = early-game ramp-up , > 1 = late-game ramp-up
@export var weight_curve : float = 1.0

@export_group("Group Spawning")
## Range of group size with lowest wave scaling. Ex: (1,1) spawns 1 asteroid. (3,5) spawns 3-5 asteroids.
@export var group_size_start : Vector2i = Vector2i(1,1)
## Range of group size with highest wave scaling. Ex: (1,1) spawns 1 asteroid. (3,5) spawns 3-5 asteroids.
@export var group_size_end : Vector2i = Vector2i(1,1)
## Wave group scaling maxes out at. Group Size Max will apply at this value.
@export var group_ramp_end_wave : int = 100
## How fast scaling happens: < 1 = early-game ramp-up , > 1 = late-game ramp-up
@export var group_curve : float = 1.0

@export_category("Drops")
@export var particle_color : Color = Color(0.44, 0.44, 0.44, 1.0)
@export var min_resources : int = 1
@export var max_resources : int
## Empty means uses base weight of resources
@export var drop_weights : Dictionary[ResourceData.ResourceType, float] = {} 

@export_group("Golden Asteroid")
@export_range(0.0, 2.0, 0.01) var golden_tint_strength : float = 1.4
@export var golden_particle_color : Color = Color("a3723b")
@export var golden_min_resources : int = 5
@export var golden_max_resources : int = 10
@export var golden_drop_weights : Dictionary[ResourceData.ResourceType, float] = { 
	ResourceData.ResourceType.GREY: 1.0, 
	ResourceData.ResourceType.BLUE: 60.0, 
	ResourceData.ResourceType.GOLD: 25.0, 
	ResourceData.ResourceType.RED: 0.5, 
} 


@export_category("AI")
@export var behavior : BehaviorType = BehaviorType.DEFAULT


# - Functions -

## Chooses random texture from Array | Applies a placeholder if empty
func get_random_texture() -> Texture2D:
	if sprite_textures.is_empty():
		var placeholder := PlaceholderTexture2D.new()
		placeholder.size = Vector2(50,50)
		return placeholder
	return sprite_textures.pick_random()

## Chooses random group size based on current_wave scaling.
func get_group_size(current_wave: int) -> int:
	
	var progress : float = clampf( (current_wave - min_wave) / maxf(group_ramp_end_wave - min_wave, 1.0) , 0.0, 1.0)
	var scaled_progress : float = pow(progress, group_curve)
	var x_lerp : int = roundi(lerpf(group_size_start.x, group_size_end.x, scaled_progress))
	var y_lerp : int = roundi(lerpf(group_size_start.y, group_size_end.y, scaled_progress))
	
	return randi_range(x_lerp, y_lerp)
	
## Returns spawn_weight of asteroid based on current_wave scaling.
func get_spawn_weight(current_wave: int) -> float:
	if spawn_weight_end < 0.0: return spawn_weight	# If weight scaling not set, returns just spawn_weight
	
	var progress : float = clampf( (current_wave - min_wave) / maxf(weight_ramp_end_wave - min_wave, 1.0) , 0.0, 1.0)
	var scaled_progress : float = pow(progress, weight_curve)
	var scaled_weight : float = lerpf(spawn_weight, spawn_weight_end, scaled_progress)
	
	return scaled_weight
