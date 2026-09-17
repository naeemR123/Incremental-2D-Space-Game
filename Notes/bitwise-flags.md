# Bits & Bitwise Flags (GDScript)

Reference note. Came up while writing `SaveData.save_dict()`, which filters
properties with `property.usage & PROPERTY_USAGE_STORAGE`.

---

## 1. What a bit is

Base 10 uses ten digits; each position is worth 10x the one to its right.
Base 2 uses two digits; each position is worth **2x** the one to its right.

```
  1    1    0    1     =  1x8 + 1x4 + 0x2 + 1x1  =  13
  8s   4s   2s   1s
```

A **bit** is one of those positions: a single slot holding 0 or 1.

Hardware works this way because a wire either carries voltage or it doesn't.
Two states is easy to build reliably; ten is not.

In GDScript:

```gdscript
print(0b1101)                      # 13      -- 0b prefix writes binary directly
print(String.num_int64(13, 2))     # "1101"  -- the 2 means "print in base 2"
```

---

## 2. Powers of two

| Bit # | Value | Binary       |
|-------|-------|--------------|
| 0     | 1     | `0b00000001` |
| 1     | 2     | `0b00000010` |
| 2     | 4     | `0b00000100` |
| 3     | 8     | `0b00001000` |
| 4     | 16    | `0b00010000` |
| 5     | 32    | `0b00100000` |
| 6     | 64    | `0b01000000` |
| 7     | 128   | `0b10000000` |

**The key property: no power of two overlaps with any other.**

Given 13, you can recover exactly which bits made it: 8 + 4 + 1. There is no
other combination that produces 13. So one integer can losslessly carry a set
of independent yes/no answers.

---

## 3. Numbers as switches

Stop reading the integer as a quantity. Read it as a row of switches.

```gdscript
const ARMORED   = 1    # 0b0001
const SPLITTING = 2    # 0b0010
const MAGNETIC  = 4    # 0b0100
const FROZEN    = 8    # 0b1000

var traits := ARMORED | MAGNETIC     # 1 | 4 = 5 = 0b0101
```

### Flags vs. enum

- An **enum** holds exactly ONE value. `AsteroidData.BehaviorType` is an enum:
  an asteroid is BOSS *or* SWARM, never both.
- **Flags** hold ANY NUMBER at once.

> When you want an enum but multiple values need to be true simultaneously,
> that's the signal to reach for flags.

---

## 4. The operators

### `|` OR -- turn bits on
Result bit is 1 if it is 1 in *either* input.

```
  0b0001   ARMORED
| 0b0100   MAGNETIC
  ------
  0b0101   both
```

### `&` AND -- test bits
Result bit is 1 only if it is 1 in *both*.

```
  0b0101   traits          0b0101   traits
& 0b0100   MAGNETIC      & 0b1000   FROZEN
  ------                   ------
  0b0100   -> 4, truthy     0b0000   -> 0, falsy
```

This is what `usage & PROPERTY_USAGE_STORAGE` does: "is that switch flipped?"
It returns the flag's value or zero, and GDScript treats 0 as falsy.

### `~` NOT -- invert every bit
Used with `&` to turn a bit *off*:

```gdscript
traits &= ~FROZEN     # clear frozen, leave everything else alone
```

`~FROZEN` is a mask with every bit set EXCEPT frozen.

Oddity: GDScript ints are 64-bit signed, so `print(~8)` shows `-9`.
Looks alarming, works correctly.

### `^` XOR -- toggle
Result bit is 1 if the inputs *differ*.

```gdscript
traits ^= FROZEN      # frozen if it wasn't, not frozen if it was
```

### `<<` `>>` shift
`1 << n` moves a single bit n places left. Preferred way to declare flags:

```gdscript
const ARMORED   = 1 << 0    # 1
const SPLITTING = 1 << 1    # 2
const MAGNETIC  = 1 << 2    # 4
const FROZEN    = 1 << 3    # 8
```

Godot's own source declares flags this way. Easier to extend -- flag ten is
`1 << 9`, no need to remember what comes after 256.

---

## 5. The idioms you'll actually write

```gdscript
traits |= FROZEN                    # set
traits &= ~FROZEN                   # clear
traits ^= FROZEN                    # toggle
if traits & FROZEN:                 # test one
```

Multi-flag tests:

```gdscript
var mask = ARMORED | MAGNETIC

if traits & mask:                   # has AT LEAST ONE of them
if (traits & mask) == mask:         # has ALL of them
```

`traits & mask` keeps only the bits present in both. If that equals the full
mask, every requested bit survived.

| traits                        | binary | `traits & mask` | `!= 0`? | `== mask`? |
|-------------------------------|--------|-----------------|---------|------------|
| `0`                           | `0000` | `0000`          | no      | no         |
| `ARMORED`                     | `0001` | `0001`          | yes     | no         |
| `MAGNETIC`                    | `0100` | `0100`          | yes     | no         |
| `ARMORED \| MAGNETIC`         | `0101` | `0101`          | yes     | **yes**    |
| `FROZEN`                      | `1000` | `0000`          | no      | no         |

---

## 6. `traits == (ARMORED | MAGNETIC)` -- why not this?

It compiles and it's valid, but it means something **stricter**:

- `traits == (A | M)` -- has EXACTLY those two and **no other flags set**
- `(traits & mask) == mask` -- has AT LEAST those two, others welcome

| traits                          | binary | `== (A\|M)` | `(t & mask) == mask` |
|---------------------------------|--------|-------------|----------------------|
| `ARMORED`                       | `0001` | no          | no                   |
| `ARMORED \| MAGNETIC`           | `0101` | **yes**     | **yes**              |
| `ARMORED \| MAGNETIC \| FROZEN` | `1101` | **no**      | **yes**              |

That last row is the problem. Exact equality couples the check to flags it has
no business knowing about. Add `FROZEN` for a slow effect three months later,
and every armored+magnetic asteroid that happens to be frozen silently stops
matching a check that has nothing to do with being frozen. Nothing errors.

Exact equality is right only when the COMPLETE set is genuinely what you're
testing -- e.g. `traits == 0` for "unmodified".

### Precedence gotcha

GDScript gives `|` HIGHER precedence than `==`, so this parses as intended:

```gdscript
if traits == ARMORED | MAGNETIC        # -> traits == (ARMORED | MAGNETIC)
```

GDScript follows Python here. But **C, C++, C# and Java do the opposite** --
`==` binds tighter, so the same line parses as `(traits == ARMORED) | MAGNETIC`,
which is always truthy. Famous C bug.

**Write the parentheses anyway.** Costs nothing, documents the grouping, and
the habit transfers safely to other languages.

---

## 7. Where Godot already uses this

- **Collision layers / masks** -- `collision_layer` = which layers a body
  occupies, `collision_mask` = which it scans. Both single ints; layer 1 is
  bit 0. That's why the Inspector shows a checkbox grid instead of a number.
  *If projectiles ever stop hitting asteroids, check the mask bits first.*
- **Property usage** -- `PROPERTY_USAGE_STORAGE`, `PROPERTY_USAGE_SCRIPT_VARIABLE`
  (used in `save_data.gd`)
- **Input modifiers** -- `InputEventKey` packs ctrl/shift/alt/meta into one field
- **Tile flipping, render layers, Tween flags** -- same pattern

---

## 8. Exporting flags

```gdscript
@export_flags("Armored", "Splitting", "Magnetic", "Frozen") var traits: int = 0
```

Godot renders a checkbox list and stores one integer, assigning `1, 2, 4, 8`
in the order listed.

> **Do not reorder that list later.** An existing resource storing `4` means
> "Magnetic" today and would silently mean whatever you moved into third
> position tomorrow. Same silent-remap failure as the `spawn_weight` rename.

---

## 9. When NOT to use bitflags

For your own game logic, `Dictionary[String, bool]` or `Array[StringName]` is
usually more readable, more debuggable, and JSON-friendly.
`print(traits)` gives `5`; `print(trait_dict)` tells you what's going on.

Bitflags earn their place when:
1. An engine API requires them (collision layers, property usage -- no choice)
2. You need to combine or compare whole sets cheaply
3. You have thousands of objects and memory actually matters
   (at 180 asteroids, this is not the bottleneck)

Learn them because Godot's API makes you fluent whether you like it or not.
Reach for them in your own code only when 1-3 applies.

---

## Scratch experiment

```gdscript
func _ready() -> void:
	var traits := 0
	traits |= ARMORED
	print(String.num_int64(traits, 2))   # 1
	traits |= MAGNETIC
	print(String.num_int64(traits, 2))   # 101
	traits &= ~ARMORED
	print(String.num_int64(traits, 2))   # 100
	traits ^= FROZEN
	print(String.num_int64(traits, 2))   # 1100
```
