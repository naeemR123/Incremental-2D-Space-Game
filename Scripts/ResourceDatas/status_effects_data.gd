class_name StatusEffectsData extends Resource

enum EffectsFamily { MODIFIER, PERIODIC }
enum StackRule { STRONGEST, REFRESH }

@export var id : String = "i.e. 'slow'"	# matches resistence keys
@export var display_name : String = "i.e. 'Slowness'"
@export_multiline var description : String = "What does this status effect do..."

@export_category("Behavior")
@export var family : EffectsFamily = EffectsFamily.MODIFIER
## FOR [code]MODIFIER[/code] EffectsFamily only.
@export var target_stat : String = "i.e. time_scale"
## FOR [code]PERIODIC[/code] EffectsFamily only.
@export var tick_interval : float = 0.5	# seconds between ticks
@export var stack_rule : StackRule = StackRule.STRONGEST

@export_category("Visuals")
@export var tint : Color = Color.WHITE
