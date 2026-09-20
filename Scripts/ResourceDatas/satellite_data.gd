extends DefenseData
class_name SatelliteData



@export_category("Orbit & Movement")
@export var orbit_radius : float = 100
@export var turn_speed : float = 10

# HDR -- feeds WorldEnvironment Bloom. Values >1.0 per channel bloom; 1.0 is normal brightness.
@export_category("Visuals")
@export var projectile_color : Color = Color(2.0, 2.0, 0.5)
