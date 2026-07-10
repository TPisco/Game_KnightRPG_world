from lowpoly import *

# --- dungeon_wall: 2m brick wall segment
cube("stone_dark",(2.0,0.4,2.4),(0,0,1.2))
for z,off in [(0.35,-0.5),(0.95,0.4),(1.55,-0.3),(2.15,0.55)]:
    cube("stone",(0.55,0.44,0.28),(off,0,z))                    # proud bricks
asset("dungeon_wall","dungeon")

# --- dungeon_wall_corner
cube("stone_dark",(2.0,0.4,2.4),(-0.2,0,1.2))
cube("stone_dark",(0.4,2.0,2.4),(-1.0,1.0,1.2))
cube("stone",(0.5,0.5,2.5),(-1.0,0,1.25))                       # corner column
asset("dungeon_wall_corner","dungeon")

# --- dungeon_floor: 2x2 stone tile
for i,(x,y) in enumerate([(-0.5,-0.5),(0.5,-0.5),(-0.5,0.5),(0.5,0.5)]):
    cube("stone" if i%2==0 else "stone_dark",(0.96,0.96,0.14),(x,y,0.07))
asset("dungeon_floor","dungeon")

# --- dungeon_pillar
cube("stone",(0.7,0.7,0.25),(0,0,0.125))
cyl("stone_dark",0.26,2.1,(0,0,1.3),v=8)
cube("stone",(0.7,0.7,0.25),(0,0,2.48))
asset("dungeon_pillar","dungeon")

# --- dungeon_pillar_broken
cube("stone",(0.7,0.7,0.25),(0,0,0.125))
cyl("stone_dark",0.26,1.1,(0,0,0.8),v=8)
cone("stone_dark",0.26,0.35,(0,0,1.5),v=8)                      # jagged top
rock("stone",0.25,(0.5,0.3,0.18),seed=61)
rock("stone_dark",0.18,(-0.45,-0.25,0.13),seed=62)
asset("dungeon_pillar_broken","dungeon")

# --- dungeon_door: arched wooden door in stone frame
cube("stone",(0.35,0.4,2.2),(-0.85,0,1.1))
cube("stone",(0.35,0.4,2.2),( 0.85,0,1.1))
cube("stone",(2.05,0.4,0.4),(0,0,2.35))
cube("wood_dark",(1.35,0.15,2.1),(0,0,1.05))
cube("iron",(1.4,0.05,0.12),(0,-0.09,1.7))
cube("iron",(1.4,0.05,0.12),(0,-0.09,0.5))
sph("gold",0.07,(0.45,-0.12,1.1))
asset("dungeon_door","dungeon")

# --- dungeon_gate: iron portcullis
cube("stone",(0.3,0.35,2.3),(-0.95,0,1.15))
cube("stone",(0.3,0.35,2.3),( 0.95,0,1.15))
cube("stone",(2.2,0.35,0.35),(0,0,2.45))
for x in np.linspace(-0.65,0.65,5):
    cyl("iron",0.05,2.2,(x,0,1.15),v=6)
for z in (0.55,1.15,1.75):
    cube("iron",(1.6,0.06,0.10),(0,0,z))
asset("dungeon_gate","dungeon")

# --- torch_sconce (dungeon variant, gold bracket)
cube("gold",(0.10,0.06,0.20),(0,-0.03,0.0))
cyl("wood_dark",0.035,0.36,(0,0.05,0.10),rot=(0.45,0,0))
cone("flame",0.08,0.20,(0,0.14,0.36),v=6)
asset("torch_sconce","dungeon")

# --- brazier
cyl("iron",0.09,0.5,(0,0,0.25),v=6)
frustum("iron",0.18,0.42,0.3,(0,0,0.62),v=10)
cone("flame",0.30,0.45,(0,0,0.95),v=8)
cone("flame",0.15,0.30,(0,0,1.15),v=6)
asset("brazier","dungeon")

# --- chest (loot chest with gold trim)
cube("wood",(0.9,0.55,0.45),(0,0,0.28))
cube("wood_dark",(0.94,0.59,0.16),(0,0,0.55))                   # lid
cube("gold",(0.96,0.10,0.50),(0,0,0.32))                        # center band
cube("gold",(0.12,0.08,0.14),(0,-0.29,0.42))                    # lock
asset("chest","dungeon")

# --- chain hook (decor)
cube("iron",(0.14,0.10,0.10),(0,0,-0.02))
for i in range(4):
    ring("iron",0.09,0.06,0.03,(0,0,-0.16-i*0.15),rot=((i%2)*np.pi/2,0,0),v=8)
asset("chain_hanging","dungeon")   # origin at top, hangs down
report()
