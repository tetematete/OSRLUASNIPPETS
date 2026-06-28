# Server Scripts
Server Scripts run on each client individually, and don't require any additional download. To use in your server, simply put the config into your CSP extra options box. The Scripts are made and tested mostly on [CSP](https://acstuff.club/patch/) version 3676 (0.3.0-preview140). 
They should be fine on most earlier versions, and I will likely update for compatibility as far back as 3465. [CSP Online Script Wiki](https://github.com/ac-custom-shaders-patch/acc-extension-config/wiki/Misc-%E2%80%93-Server-extra-options#online-scripts)

Extra Options Can be found here using CM server:

<img width="725" height="201" alt="image" src="https://github.com/user-attachments/assets/40137707-9e79-4282-9908-056b4c5b428b" />


Or here using ACSM: (Make sure "Enable Extra Custom Shaders Patch Options" is enabled in server options!)

<img width="725" alt="image" src="https://github.com/user-attachments/assets/8c85d7c8-5fdb-40a2-8d3f-6a386751bb1f" />


## Betterflags
Better flag implementation! Adds Meatball Flag, No-overtake zones, and Slow Car Ahead flag from ACC. Can display them all in parallel.

If you open the "Chat" app, and click the lightbulb, you can preview and move the flags anywhere on screen.

Put the following into your AC server CSP EXTRA OPTIONS:
```ini
[SCRIPT_...]
SCRIPT = "https://raw.githubusercontent.com/tetematete/OSRLUASNIPPETS/refs/heads/main/Server%20Scripts/betterflags.lua"

[BETTERFLAGS]
NO_OVERTAKE=(|0.2=1|0.3=0|0.5=1|0.6=0|) ;No Overtake Zone LUT, (|0-1 track progress=1 on, 0 off|)
;Above example turns on at 0.2 track progress, off at 0.3, on at 0.5, off at 0.6
;Use the track coordinates app from the ingame App Shelf app to quickly find the track coordinates.
MEATBALL_THRESHOLD=0.10 ;Suspension Damage Threshold to display meatball flag. Value from 0-1. Lower = more sensitive.
SLOW_CAR_WARN_DISTANCE=500,100 ;how far in front and behind to enable slow car. (500,100 means slow car flag would be active 500m before and 100m after slow car)
SLOW_CAR_PENALTY=-1,5 ; -1 for no penalty (white flag) , 0 for chat message (code60 flag), anything above will be laps to serve drive through (code60 flag). 
;optional second value is how long people have to slow down to 60kmh. 
ENABLE_PHYSICS_FLAGS=1 ;experimental, activates ac yellow under slow car conditions.
```

## Holdbrakes
TeTeMaTeTe's awesome hold brakes reminder online script!

Is your server populated by people who don't know how to hold their brakes after a spin?
Worry no more! This online script gives them a gentle reminder to hold their brakes shortly after losing control of their 2 ton death machine.

IMPORTANT CONFIG STUFF
Put the following into your AC server CSP EXTRA OPTIONS:
```ini
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
```ini
[SCRIPT_...]
SCRIPT = "https://raw.githubusercontent.com/tetematete/OSRLUASNIPPETS/refs/heads/main/Server%20Scripts/acsrtags.lua"

[ACSRTAGS]
CHAMPIONSHIP_URL="http://127.0.0.1:8772/championship/000000000000-0000-0000-0000-000000000000" ;Replace this with the link of the championship the race is taking place in.
```

## Evil AGA (Advanced Gamepad Assist)
Acts as an override for gamepad assist scripts. To be used in places where strong assists could have an affect on competitive integrity.

This one pretty much just came to me in a dream. relatively untested, allegedly breaks cmrt leaderboard somehow but im really not sure how that could be the case. 

If user at or above patch level 3978, runs at physics rate instead of graphics rate.
```ini
[SCRIPT_...]
SCRIPT = "https://raw.githubusercontent.com/tetematete/OSRLUASNIPPETS/refs/heads/main/Server%20Scripts/evilAGA.lua"
```

## Start Lights
Adds a whole new start light system to AC! 

Trigger a start light sequence from the chat app, it will sync on all clients and apply penalties for jump starts. Posts reaction times in chat on successful starts, and the opposite on jumpstarts. Includes fallback lights texture in case the proper one cant be found.

Great for F1 style starts with a real formation/warm-up lap. Can add randomness to lights out so you cant just time the start.
```ini
[SCRIPT_...]
SCRIPT = "https://raw.githubusercontent.com/tetematete/OSRLUASNIPPETS/refs/heads/main/Server%20Scripts/startLights.lua"

[STARTLIGHTS]
PENALTY_TYPE=-1 ;-2 for gearbox locked until start, -1 for no Penalty, 0 for teleport to pits, above 0 will be laps to serve drive through.
RANDOM_DELAY_RANGE=3,5 ;minimum and maximum time in seconds from all lights being on to lights out. set to the same number to remove start randomization
ADMIN_ONLY=1 ;1 means only admins can use the tool. 0 means anyone can begin a start sequence at any time, great for messing around with friends or on a server for practice race starts. If penalties are set you should really keep this to 1. 
SEQUENCE_LENGTH=17 ;Time from lights appearing on screen to all lights being red in seconds.
SEQUENCE_START=12 ;Time to start turning on lights in seconds, should be lower than SEQUENCE_LENGTH.
;For example length 17 and start 12 would be 17 seconds from start to all lights on, after 12 of said 17 seconds lights would begin to turn on.
REPLACE_AC_START=0 ;set to 1 to override the original start lights behaviour at the start of race sessions.
;ICON_URL="https://static.wikia.nocookie.net/rfti/images/6/68/Jerman.png" ;URL of a custom icon to use for the lights, image size doesnt matter, as it will get scaled to 64x64 to match AC ui placement.
DEBUG_MODE = 0 ;Optional Logging and chat spam for troubleshooting problems.
F1_STYLE = 0 ;Set to 1 to enable f1-style starts. Makes it so that someone must manually trigger the lights out.
F1_STYLE_DELAY = 50; Buffer time to allow clients to sync properly after manual start triggered. Lower = more chance of desync, Higher = more time for external scripts to react.
```
## Tyre Blankies
Overrides the AC tyre blanket temps. Applies to all cars.
```ini
[SCRIPT_...]
SCRIPT = "https://raw.githubusercontent.com/tetematete/OSRLUASNIPPETS/refs/heads/main/Server%20Scripts/tyreblankies.lua"

[BLANKIES]
TEMP_DEGC = 70 ;Desired tyre temp in degrees celsius 
```

## Rubberband
finished up an old script I had laying around. For less serious races where having fun is the priority. Automatically applies restrictor/ballast based on gap to leader.
```ini
[SCRIPT_...]
SCRIPT="https://raw.githubusercontent.com/tetematete/OSRLUASNIPPETS/refs/heads/main/Server%20Scripts/rubberband.lua"

[RUBBERBAND]
BALLAST=(|0=100|5=50|10=-200|) ;Linear Lookup Table Format (|secondsToLeader=ballast|)
;Max Ballast 5000kg, going past negative 500 bad for game and bad for handling.
RESTRICTOR=(|0=200|10=0|) ;(|secondsToLeader=restrictor%|)
;Max Restrictor 400%, doesnt support negatives afaik
ACTIVE_ON_LAP=0 ;Activate when leader is on this lap. 0 is active from start.
ACTIVE_PQR=0,0,1 ;What session types to activate rubberbanding. P/Q untested. 
;0,0,1 is disabled in practice, quali; enabled in race
SEC_PER_UPDATE=0.5 ;Performance is mildly worse than I expected so turn this up if there are issues. 0 runs every frame.
```

## Assist Penalties
basically just the same system from LMU. Should be used with TC and ABS forced on. 
If a penalty is enabled (not 0,0), then lock user to above/below assist level 1, and apply penalty if above 0. Can be set per car.  
```ini
[SCRIPT_...] 
SCRIPT = "https://raw.githubusercontent.com/tetematete/OSRLUASNIPPETS/refs/heads/main/Server%20Scripts/assistPenalties.lua"

[ASSISTPEN_...] ;adding _... should automatically index sections. Add a new section for each per-car(s) set of penalties to apply.
CAR_FOLDER=ks_car1, ks_car2 ; Folder names of cars this section applies to, separated by comma
TC_RES_BAL=5,20,0 ;Penalty for TC ON, Restrictor%, BallastKG respectively.
;Third value is optional, used to set defaults upon loading in. New main menu shows forced assists as disabled on first loading in even when the actual value is like 3, which is obviously a problem when the script makes you live with your decision until you can apply a new setup.
;Match it with whatever new main menu says default is. 
ABS_RES_BAL=10,40,0 ;Penalty for ABS ON, Restrictor%, BallastKG respectively.

[ASSISTPEN_...]
;Omitting car folder acts as "other", applies to all cars not already defined with CAR_FOLDER. If having different penalties is not neccessary, neither is CAR_FOLDER.  
TC_RES_BAL=0,0 ;omitting key or putting 0,0 means assist should be unlocked. 
ABS_RES_BAL=10,40 ;This example would be best on a car with factory TC, No factory ABS
```

## Attackmode
Attack mode! This implements the attack mode from formula E into the game, and is, at the moment, hardcoded for use with the VRC CSP Formula Lithium. It wouldnt be hard to add functionality for all p2p cars but i just need someone to give me a reason lmao.

Easily add attack mode arrows that activate p2p upon driving through them. Server scripts can't directly disallow KERS, only disable the button input, so if KERS is activated externally, like via an app, when its not allowed, the driver's clutch will be locked to 50% for the duration of the attack mode as punishment.

When adjusting the hitbox, keep in mind the car's "hitbox" is a single point at the center of the car, so set it generously.

I'll let this demo video do the rest of the explaining :)
https://youtu.be/dSbHR5Fc_Mg

```ini
[SCRIPT_...]
SCRIPT = "https://raw.githubusercontent.com/tetematete/OSRLUASNIPPETS/refs/heads/main/Server%20Scripts/attackmode.lua"

[ATTACKMODE]
SIZE=1 ;Don't try to set these manually
HITBOX=2 ;The script comes with a tool
DIST=1 ;You need to join the server as admin to access it
POINT_0=1,1,1 ;settting these manually is stupid
```


