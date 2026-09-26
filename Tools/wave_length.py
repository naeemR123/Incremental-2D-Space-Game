import csv
import tkinter as tk
from tkinter import ttk

import matplotlib.pyplot as plt

# window
window = tk.Tk()
window.title("Wave Length Chart")

# screen attributes
screen_width = window.winfo_screenwidth()   # Returns screen width in px
screen_height = window.winfo_screenheight() # Returns screen height in px

# window properties
window_width = 800
window_height = 600

# Calculates values for centering the window on the screen
win_x_offset = screen_width/2-window_width/2
win_y_offset = screen_height/2-window_height/2

# The method below centers the window on the screen. Results NEED to be integer values to avoid errors (there are no half pixels).
window.geometry(f"{window_width}x{window_height}+{int(win_x_offset)}+{int(win_y_offset)}")


# ---- Mirror of wave_manager.gd: keep in sync! ----
SCALING_END_WAVE = 100
MAX_ASTEROIDS_CAP = 180

MAX_SPAWN_INTERVAL = 7.0
MIN_SPAWN_INTERVAL = 0.5
INTERVAL_CURVE = 0.6

# ---- Option 2 placeholders ----
WAVE_DURATION_START = 30.0
WAVE_DURATION_END = 120.0
DURATION_CURVE = 0.8

# Functions

# ---- Helper functions ---- 

# Clamp Helper Function
def clamp(value, min_value, max_value):
    return max(min(value, max_value), min_value)

# Linear Interpolation Helper Function
def lerp(start, end, weight):
    return start + (end - start) * weight

# ---- Wave functions ----

# Returns the number of asteroids to spawn
def get_max_asteroids(wave):
    return clamp(3 + (wave * 2), 1, MAX_ASTEROIDS_CAP)

# Returns the progress of the wave, from 0 to 1
def get_wave_progress(wave):
    weight = (wave - 1)/(SCALING_END_WAVE - 1)
    return clamp(weight, 0, 1)

# Returns the spawn interval of asteroids for current wave
def get_spawn_interval(wave):
    wave_progress = get_wave_progress(wave)
    return lerp(MAX_SPAWN_INTERVAL, MIN_SPAWN_INTERVAL, wave_progress ** INTERVAL_CURVE)

# Returns the length of the current wave in seconds
def get_wave_length(wave):
    return (get_max_asteroids(wave) - 1) * get_spawn_interval(wave)

# Returns the duration of the target wave duration for current wave
def get_target_duration(wave):
    wave_progress = get_wave_progress(wave)
    return lerp(WAVE_DURATION_START, WAVE_DURATION_END, wave_progress ** DURATION_CURVE)

# ---- Option 2 Functions ----

def get_option_2_spawn_interval(wave):
    return max(get_target_duration(wave)/(get_max_asteroids(wave) - 1), MIN_SPAWN_INTERVAL)

def get_option_2_wave_length(wave):
    return (get_max_asteroids(wave) - 1) * get_option_2_spawn_interval(wave)


# ---- Widgets

# Treeview
table = ttk.Treeview(
    window,
    columns=("Wave", "Max Asteroids", "Spawn Interval", "Wave Length", "Opt 2 Spawn Interval", "Opt 2 Wave Length","Wave Progress"),
    show="headings",
)
table.pack(fill="both", expand=True, padx=20, pady=20)

# Data
table.heading("Wave", text="Wave")
table.heading("Max Asteroids", text="Max Asteroids")
table.heading("Spawn Interval", text="Spawn Interval (s)")
table.heading("Wave Length", text="Wave Length (s)")
table.heading("Opt 2 Spawn Interval", text="Opt 2 Spawn Interval (s)")
table.heading("Opt 2 Wave Length", text="Opt 2 Wave Length (s)")
table.heading("Wave Progress", text="Wave Progress (%)")

# Column Sizing
table.column("Wave", width=10)
table.column("Max Asteroids", width=35)
table.column("Spawn Interval", width=65)
table.column("Wave Length", width=65)
table.column("Opt 2 Spawn Interval", width=75)
table.column("Opt 2 Wave Length", width=75)
table.column("Wave Progress", width=30)


# -- Run

# Write to CSV
with open("wave_manager.csv", "w", newline="") as file:
    writer = csv.writer(file)
    writer.writerow(["Wave", "Max Asteroids", "Spawn Interval (s)", "Wave Length (s)", "Option 2 Spawn Interval (s)", "Option 2 Wave Length (s)", "Wave Progress (%)"])

    for i in range(1, SCALING_END_WAVE + 1):

        # Variables
        wave = i
        max_asteroids = get_max_asteroids(i)
        spawn_interval = get_spawn_interval(i)
        wave_length = get_wave_length(i)
        opt_2_spawn_interval = get_option_2_spawn_interval(i)
        opt_2_wave_length = get_option_2_wave_length(i)
        wave_progress = get_wave_progress(i)

        # Table Tuple
        table_values = (wave, max_asteroids, spawn_interval, wave_length, opt_2_spawn_interval, opt_2_wave_length, wave_progress)

        # Table Insert
        table.insert(parent="", index="end", values=(table_values[0], table_values[1], f"{table_values[2]:.2f}", f"{table_values[3]:.2f}s", f"{table_values[4]:.2f}", f"{table_values[5]:.2f}s", f"{(table_values[6]*100):.2f}%"))

        # Writer
        writer.writerow(table_values)

window.mainloop()