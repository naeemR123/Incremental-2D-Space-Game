class_name EffectIDs




##############
# Effect IDs #  -- matches StatusEffectsData.id | keys AsteroidData.resistances, identifies which .tres to apply

const SLOW = "slow"
const BURN = "burn"
const ACID = "acid"
const PROTECTION = "protection"


###################
# Target Stat IDs #  -- matches StatusEffectsData.target_stat | what a MODIFIER effect scales, read via get_modifier()

const TIME_SCALE = "time_scale"
const DAMAGE_TAKEN = "damage_taken"


###############
# Source Keys #  -- identifies WHO applied an effect | for apply_effect()/remove_effect() calls

const TRACTOR_BEAM = "tractor_beam"
const PROJECTILE = "projectile"
