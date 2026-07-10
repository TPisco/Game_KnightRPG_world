from lowpoly import *

# --- stone_wall: low field wall 2m
cube("stone_dark",(2.0,0.5,0.9),(0,0,0.45))
rock("stone",0.28,(-0.7,0,0.95),seed=71,scale=(1.2,0.9,0.6))
rock("stone",0.26,(0.1,0.05,0.98),seed=72,scale=(1.1,0.8,0.6))
rock("stone",0.27,(0.75,-0.03,0.94),seed=73,scale=(1.15,0.85,0.6))
asset("stone_wall","props")

# --- fence_wood: 2m rail fence
cube("wood_dark",(0.12,0.12,1.1),(-0.9,0,0.55))
cube("wood_dark",(0.12,0.12,1.1),( 0.9,0,0.55))
cube("wood",(2.0,0.08,0.14),(0,0,0.85))
cube("wood",(2.0,0.08,0.14),(0,0,0.45))
asset("fence_wood","props")

# --- ruin_arch
cube("stone",(0.55,0.55,2.2),(-1.0,0,1.1))
cube("stone",(0.55,0.55,1.7),( 1.0,0,0.85))                     # broken side, shorter
cube("stone_dark",(1.6,0.5,0.45),(-0.35,0,2.35))                # partial lintel
rock("stone",0.3,(1.2,0.4,0.2),seed=81)
rock("stone_dark",0.22,(0.6,-0.45,0.15),seed=82)
asset("ruin_arch","props")

# --- ruin_wall: crumbling wall
cube("stone_dark",(2.2,0.45,1.0),(0,0,0.5))
cube("stone_dark",(1.1,0.45,0.7),(-0.55,0,1.35))                # upper remnant
cube("stone",(0.5,0.48,0.4),(0.6,0,1.15))
rock("stone",0.25,(1.1,0.5,0.18),seed=83)
asset("ruin_wall","props")

# --- pillar_ruined (overworld grey marble)
cube("stone",(0.8,0.8,0.22),(0,0,0.11))
cyl("stone",0.28,1.4,(0,0,0.9),v=9)
cone("stone",0.28,0.4,(0,0,1.8),v=9)
asset("pillar_ruined","props")

# --- sign_post: directional arrow sign
cyl("wood_dark",0.07,1.7,(0,0,0.85),v=6)
cube("wood_light",(0.85,0.07,0.30),(0.30,0,1.45))
cone("wood_light",0.155,0.22,(0.83,0,1.45),rot=(0,np.pi/2,0),v=4)  # arrow tip
cube("wood_light",(0.7,0.07,0.26),(-0.25,0,1.05),rot=(0,0,np.pi)) # second board
asset("sign_post","props")

# --- lamp_post
cube("stone_dark",(0.4,0.4,0.15),(0,0,0.075))
cyl("iron",0.06,2.2,(0,0,1.25),v=6)
cube("iron",(0.55,0.08,0.08),(0.20,0,2.35))
cube("dark",(0.30,0.30,0.40),(0.38,0,2.15))                     # lantern box
sph("flame",0.11,(0.38,0,2.15))                                 # glow core
cone("iron",0.24,0.18,(0.38,0,2.42),v=4)
asset("lamp_post","props")

# --- tree_pine
cyl("wood",0.16,0.9,(0,0,0.45),v=7)
cone("leaf_dark",0.95,1.1,(0,0,1.45),v=8)
cone("leaf",0.72,1.0,(0,0,2.15),v=8)
cone("leaf",0.45,0.9,(0,0,2.8),v=8)
asset("tree_pine","props")

# --- tree_oak
cyl("wood",0.20,1.1,(0,0,0.55),v=7)
cube("wood",(0.5,0.14,0.14),(0.35,0,1.2),rot=(0,-0.7,0))        # branch
ico("leaf",0.85,(0,0,1.9),sub=1,scale=(1.15,1.1,0.9))
ico("leaf_dark",0.5,(0.6,0.3,1.55),sub=1)
ico("leaf",0.45,(-0.55,-0.2,1.7),sub=1)
asset("tree_oak","props")

# --- bush
ico("leaf_dark",0.45,(0,0,0.35),sub=1,scale=(1.2,1.1,0.8))
ico("leaf",0.28,(0.35,0.2,0.3),sub=1)
asset("bush","props")

# --- well
ring("stone_dark",0.75,0.55,0.7,(0,0,0.35),v=10)
cube("wood_dark",(0.10,0.10,1.5),(-0.62,0,1.1))
cube("wood_dark",(0.10,0.10,1.5),( 0.62,0,1.1))
cube("cloth_red",(1.7,1.0,0.10),(-0.4,0,1.95),rot=(0,0.5,0))
cube("cloth_red",(1.7,1.0,0.10),( 0.4,0,1.95),rot=(0,-0.5,0))
cyl("wood",0.08,1.1,(0,0,1.55),rot=(np.pi/2,0,0),v=6)           # axle
sph("iron",0.09,(0,0,1.05))                                     # bucket hint
asset("well","props")

# --- gravestone
cube("stone_dark",(0.6,0.18,0.8),(0,0,0.4))
cyl("stone_dark",0.30,0.18,(0,0,0.8),rot=(np.pi/2,0,0),v=10)    # rounded top
cube("stone",(0.4,0.20,0.06),(0,0,0.55))                        # inscription band
asset("gravestone","props")
report()
