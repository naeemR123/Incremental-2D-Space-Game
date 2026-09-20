extends Resource
class_name ResourceData


enum ResourceType { GREY, BLUE, GOLD, RED, }
const WEIGHT_SUFFIX = "_weight_mult"


@export var resource_type : ResourceType = ResourceType.GREY
@export var value : int
## Should match resource_type and string in [code]unlock_ids.gd[/code]. Leave blank to be auto-unlocked. [br] Ex: "gold" = unlocked when gold resources unlocked in perks.[br] Ex: "" = unlocked on game start
@export var unlock_id : String = ""

@export_category("Texture")
@export var textures : Array[Texture2D]
@export var glow : bool = false
@export var glow_color : Color

@export_category("Spawning")
@export var base_weight : float


## Gets random texture from [code]textures[/code] array. If no textures are present, then uses a placeholder texture.
func get_random_texture() -> Texture2D:
	if textures.is_empty():
		var placeholder := PlaceholderTexture2D.new()
		placeholder.size = Vector2(25,25)
		return placeholder
	return textures.pick_random()


func get_weight_stat_id() -> String:
	return ResourceType.keys()[resource_type].to_lower() + WEIGHT_SUFFIX
