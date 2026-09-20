class_name NumberFormat

# Number display helpers | Used by UI scripts
# ex. "10249627.92" = "10.2M"


const SUFFIXES : Array[String] = ["", "K", "M", "B", "T",]
const STEP : float = 1000.0


## Compacts large number for display , returns [code]String[/code] | Ex. 29504537.64094 -> "29.5M"
static func compact(value: float) -> String:
	# Stores if value is positive or negative, and the absolute of value
	var sign_str : String = "-" if value < 0 else ""
	var abs_val : float = absf(value)
	
	var index : int = 0
	while abs_val >= STEP and index < SUFFIXES.size() - 1: 
		abs_val /= STEP
		index += 1
	
	var suffix : String = SUFFIXES[index]
	var decimals : int
	
	if abs_val < 10.0:
		decimals = 2
	elif abs_val < 100.0:
		decimals = 1
	else:
		decimals = 0
	
	var formatted_val : float = _truncate(abs_val, decimals)
	var format_string : String = "%%.%df" % decimals		# Returns formatting string based on decimal amount
	
	var output_val : String = format_string % formatted_val
	
	if "." in output_val:
		output_val = output_val.rstrip("0").rstrip(".")
	
	# If no decimal needed, then returns int val
	# Ex. 1: 43.06 returns "43"
	# Ex. 2: -2485.29 returns "-2.48K"
	return sign_str + output_val + suffix 

# Returns floored float based on decimal amount | Ex. 5.289435 = 5.28
static func _truncate(value: float, decimals: int) -> float:
	# What to divide by to get floored float based on decimal amount
	var factor : float = pow(10.0, decimals)				# Ex. 1.285849 (2 decimals) = pow(10.0, 2) = 100
	# Returns value formatted to a float 
	var formatted_val : float = floorf(value * factor) / factor 	# Ex. floorf(1.285849 * 100) / 100 = 1.28
	
	return formatted_val
