from lowpoly import *

# --- shop_building v2: clean pyramid roof, timber frame, readable door
cube("stone_dark",(4.4,4.4,0.30),(0,0,0.15))                    # foundation
cube("parchment",(4.0,4.0,2.30),(0,0,1.45))                     # walls
for x in (-1.9,1.9):
    cube("wood_dark",(0.20,0.20,2.30),(x,-1.95,1.45))
    cube("wood_dark",(0.20,0.20,2.30),(x, 1.95,1.45))
cube("wood_dark",(4.1,0.16,0.16),(0,-2.0,2.20))                 # front beam
cube("wood_dark",(4.1,0.16,0.16),(0, 2.0,2.20))
cube("wood_dark",(0.16,4.1,0.16),(-2.0,0,2.20))
cube("wood_dark",(0.16,4.1,0.16),( 2.0,0,2.20))
cube("wood_dark",(1.0,0.18,1.9),(0,-2.02,0.95))                 # door (front face -Y)
cube("gold",(0.10,0.06,0.10),(0.32,-2.10,0.95))                 # handle
cube("wood_dark",(1.24,0.14,0.14),(0,-2.05,1.97))               # lintel
for wx in (-1.25,1.25):                                         # front windows
    cube("dark",(0.85,0.06,0.7),(wx,-2.01,1.45))
    cube("wood_light",(0.95,0.05,0.10),(wx,-2.04,1.45))
    cube("wood_light",(0.10,0.05,0.78),(wx,-2.04,1.45))
cube("wood",(4.7,4.7,0.16),(0,0,2.68))                          # eaves slab
cone("cloth_red",3.15,1.5,(0,0,3.51),rot=(0,0,np.pi/4),v=4)     # pyramid roof
cube("gold",(0.18,0.18,0.30),(0,0,4.35))                        # finial
# hanging sign by the door
cube("wood_dark",(0.10,0.10,0.9),(0.95,-2.25,2.15))
cube("wood_dark",(0.7,0.08,0.08),(0.80,-2.42,2.55),rot=(0,0,0.5))
cube("wood_light",(0.55,0.06,0.40),(0.62,-2.58,2.22))
sph("glass_red",0.10,(0.62,-2.62,2.22))
asset("shop_building","shop")

# --- chest v2: wrap-around gold band
cube("wood",(0.9,0.55,0.45),(0,0,0.28))
cube("wood_dark",(0.94,0.59,0.16),(0,0,0.55))
cube("gold",(0.14,0.62,0.52),(0,0,0.30))                        # band wraps front-to-back over top
cube("gold",(0.12,0.08,0.14),(0,-0.30,0.42))                    # lock
asset("chest","dungeon")

# --- chain_hanging v2: connected links
cube("iron",(0.14,0.10,0.10),(0,0,-0.02))
for i in range(5):
    ring("iron",0.085,0.055,0.03,(0,0,-0.12-i*0.115),rot=((i%2)*np.pi/2,0,0),v=8)
asset("chain_hanging","dungeon")

# --- dungeon_wall v2: visible brick relief
cube("stone_dark",(2.0,0.4,2.4),(0,0,1.2))
for z,off in [(0.35,-0.5),(0.95,0.4),(1.55,-0.3),(2.15,0.55)]:
    cube("stone",(0.55,0.52,0.30),(off,0,z))
asset("dungeon_wall","dungeon")

cube("stone_dark",(2.0,0.4,2.4),(-0.2,0,1.2))
cube("stone_dark",(0.4,2.0,2.4),(-1.0,1.0,1.2))
cube("stone",(0.55,0.55,2.5),(-1.0,0,1.25))
cube("stone",(0.5,0.52,0.30),(0.3,0,0.6))
cube("stone",(0.5,0.52,0.30),(0.5,0,1.7))
cube("stone",(0.52,0.5,0.30),(-1.0,0.8,1.1))
asset("dungeon_wall_corner","dungeon")

# --- well v2: proper tent roof (panels rise toward center ridge)
ring("stone_dark",0.75,0.55,0.7,(0,0,0.35),v=10)
cube("wood_dark",(0.10,0.10,1.5),(-0.62,0,1.1))
cube("wood_dark",(0.10,0.10,1.5),( 0.62,0,1.1))
cube("cloth_red",(1.15,1.3,0.10),(-0.42,0,1.95),rot=(0,-0.55,0))
cube("cloth_red",(1.15,1.3,0.10),( 0.42,0,1.95),rot=(0, 0.55,0))
cube("wood_dark",(0.12,1.35,0.12),(0,0,2.26))                   # ridge
cyl("wood",0.08,1.1,(0,0,1.55),rot=(np.pi/2,0,0),v=6)
sph("iron",0.09,(0,0,1.05))
asset("well","props")
report()
