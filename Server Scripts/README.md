# Server Scripts
Server Scripts run on each client individually, and don't require any additional download. To use in your server, simply put the config into your CSP extra options box. The Scripts are made and tested mostly on [CSP](https://acstuff.club/patch/) version 3676 (0.3.0-preview140). 
They should be fine on most earlier versions, and I will likely update for compatibility as far back as 3334. [CSP Online Script Wiki](https://github.com/ac-custom-shaders-patch/acc-extension-config/wiki/Misc-%E2%80%93-Server-extra-options#online-scripts)

Extra Options Can be found here using CM server:

<img width="725" height="201" alt="image" src="https://github.com/user-attachments/assets/40137707-9e79-4282-9908-056b4c5b428b" />


Or here using ACSM: (Make sure "Enable Extra Custom Shaders Patch Options" is enabled in server options!)

<img width="725" alt="image" src="https://github.com/user-attachments/assets/8c85d7c8-5fdb-40a2-8d3f-6a386751bb1f" />


## Betterflags
Better flag implementation! Adds Meatball Flag, No-overtake zones, and Slow Car Ahead flag from ACC. Can display them all in parallel.

If you open the "Chat" app, and click the lightbulb, you can preview and move the flags anywhere on screen.

Put the following into your AC server CSP EXTRA OPTIONS:
```
[SCRIPT_...]
SCRIPT = "https://raw.githubusercontent.com/tetematete/OSRLUASNIPPETS/refs/heads/main/Server%20Scripts/betterflags.lua"

[BETTERFLAGS]
NO_OVERTAKE_ZONE_1=0.2,0.3 ;Defines the First no-overtake zone as two points on track, flag will be displayed between them.
NO_OVERTAKE_ZONE_2=0,0 ;Use the track coordinates app from the ingame App Shelf app to quickly find the track coordinates.
NO_OVERTAKE_ZONE_3=0,0
MEATBALL_THRESHOLD=0.10 ;Suspension Damage Threshold to display meatball flag. Value from 0-1. Lower = more sensitive.
SLOW_CAR_FLAG_PERSIST=1.1 ;How long to leave the slow car flag onscreen in seconds.
SLOW_CAR_WARN_DISTANCE=0.1 ;How far back to warn players of a slow car ahead, in % of track distance. Will be changed to metres in future.
```

## Holdbrakes
TeTeMaTeTe's awesome hold brakes reminder online script!

Is your server populated by people who don't know how to hold their brakes after a spin?
Worry no more! This online script gives them a gentle reminder to hold their brakes shortly after losing control of their 2 ton death machine.

IMPORTANT CONFIG STUFF
Put the following into your AC server CSP EXTRA OPTIONS:
```
[SCRIPT_...]
SCRIPT = "https://raw.githubusercontent.com/tetematete/OSRLUASNIPPETS/refs/heads/main/Server%20Scripts/holdbrakes.lua"

[HOLDBRAKES]
TARGET_RATE_OF_CHANGE=100 ;Sensitivity of the script, lower numbers display warning earlier. rate of change graph avaliable in lua debug app to help with picking the right value
DISPLAY_WARNING_FOR=5 ;Time in seconds to display warning for
FORCE_VICTIM_BRAKES=0 ;0 off, 1 on | automatically holds brakes for warning duration. Ensure the Target rate of change is tuned well. Or don't. lmao.
```

## ACSR Tags
Changes the driver tags ingame to display Driver Safety and Skill Rating from ACSR. Requires ACSM 2.4.13+

Displays events remaining for provisional drivers. Uses championship endpoint, so will only work for drivers registered in ACSR-enabled championship. Races should also be started from said championship, or using the start practice session button.

It can be disabled from the chat app.
```
[SCRIPT_...]
SCRIPT = "https://raw.githubusercontent.com/tetematete/OSRLUASNIPPETS/refs/heads/main/Server%20Scripts/acsrtags.lua"

[ACSRTAGS]
CHAMPIONSHIP_URL="http://127.0.0.1:8772/championship/000000000000-0000-0000-0000-000000000000" ;Replace this with the link of the championship the race is taking place in.
```

## Evil AGA (Advanced Gamepad Assist)
Acts as an override for gamepad assist scripts. To be used in places where strong assists could have an affect on competitive integrity.

This one pretty much just came to me in a dream. relatively untested, allegedly breaks cmrt leaderboard somehow but im really not sure how that could be the case. 
```
[SCRIPT_...]
SCRIPT = "https://raw.githubusercontent.com/tetematete/OSRLUASNIPPETS/refs/heads/main/Server%20Scripts/evilAGA.lua"
```
