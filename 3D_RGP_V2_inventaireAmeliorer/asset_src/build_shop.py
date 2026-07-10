from lowpoly import *

# --- shop_building: timber-frame shop, door reads enterable, hanging sign
cube("stone_dark",(4.4,4.4,0.30),(0,0,0.15))                    # foundation
cube("parchment",(4.0,4.0,2.30),(0,0,1.45))                     # walls
for x in (-1.9,1.9):                                            # corner beams
    cube("wood_dark",(0.20,0.20,2.30),(x,-1.95,1.45))
    cube("wood_dark",(0.20,0.20,2.30),(x, 1.95,1.45))
cube("wood_dark",(4.1,0.16,0.16),(0,-2.0,2.52))                 # front beam
cube("wood_dark",(4.1,0.16,0.16),(0, 2.0,2.52))
cube("wood_dark",(0.16,4.1,0.16),(-2.0,0,2.52))
cube("wood_dark",(0.16,4.1,0.16),( 2.0,0,2.52))
cube("wood_dark",(1.0,0.18,1.9),(0,-2.02,0.95))                 # door (front -Y... facing +Y? door on +Y)
cube("wood_dark",(1.0,0.18,1.9),(0,-2.02,0.95))
cube("gold",(0.10,0.06,0.10),(0.32,-2.10,0.95))                 # handle
cube("wood_dark",(1.24,0.10,0.12),(0,-2.06,1.96))               # door lintel
cube("dark",(0.9,0.06,0.7),(-1.2,-2.01,1.55))                   # window L
cube("wood_light",(1.0,0.05,0.10),(-1.2,-2.03,1.55))            # window cross
cube("wood_light",(0.10,0.05,0.8),(-1.2,-2.03,1.55))
cube("dark",(0.9,0.06,0.7),( 1.2,-2.01,1.55))
cube("wood_light",(1.0,0.05,0.10),( 1.2,-2.03,1.55))
cube("wood_light",(0.10,0.05,0.8),( 1.2,-2.03,1.55))
# gabled roof from two rotated slabs
cube("cloth_red",(3.4,5.0,0.18),(-1.25,0,3.30),rot=(0,0.62,0))
cube("cloth_red",(3.4,5.0,0.18),( 1.25,0,3.30),rot=(0,-0.62,0))
cube("wood_dark",(0.22,5.02,0.22),(0,0,4.05))                   # ridge beam
cube("parchment",(4.0,4.0,0.9),(0,0,2.95),rot=(0,0,0))          # gable fill
# hanging sign by the door
cube("wood_dark",(0.10,0.10,0.9),(0.95,-2.25,2.25))
cube("wood_dark",(0.7,0.08,0.08),(0.70,-2.45,2.62),rot=(0,0,0.5))
cube("wood_light",(0.55,0.06,0.40),(0.55,-2.62,2.30))
sph("glass_red",0.10,(0.55,-2.66,2.30))                         # potion emblem
asset("shop_building","shop")

# --- shop_counter
cube("wood",(1.8,0.6,0.9),(0,0,0.45))
cube("wood_light",(1.95,0.75,0.08),(0,0,0.94))
cube("wood_dark",(1.8,0.05,0.25),(0,-0.32,0.60))                # front trim
asset("shop_counter","shop")

# --- shop_shelf
cube("wood_dark",(0.08,0.35,1.8),(-0.66,0,0.9))
cube("wood_dark",(0.08,0.35,1.8),( 0.66,0,0.9))
for z in (0.35,0.85,1.35):
    cube("wood_light",(1.4,0.32,0.06),(0,0,z))
cube("wood",(1.4,0.06,1.8),(0,0.16,0.9))                        # back panel
asset("shop_shelf","shop")

# --- shop_table
cube("wood_light",(1.1,0.8,0.07),(0,0,0.72))
for x,y in ((-0.48,-0.33),(0.48,-0.33),(-0.48,0.33),(0.48,0.33)):
    cube("wood",(0.09,0.09,0.72),(x,y,0.36))
asset("shop_table","shop")

# --- shop_stool
cyl("wood_light",0.22,0.06,(0,0,0.45),v=8)
for i in range(3):
    a=i*2.1
    cube("wood",(0.06,0.06,0.45),(np.cos(a)*0.14,np.sin(a)*0.14,0.22),rot=(0.15*np.sin(a),0.15*np.cos(a),0))
asset("shop_stool","shop")

# --- barrel
frustum("wood",0.30,0.34,0.45,(0,0,0.32),v=10)
frustum("wood",0.34,0.30,0.45,(0,0,0.77),v=10)                  # bulge halves... two frustums
ring("iron",0.36,0.32,0.06,(0,0,0.25),v=10)
ring("iron",0.36,0.32,0.06,(0,0,0.85),v=10)
cyl("wood_light",0.30,0.04,(0,0,1.00),v=10)
asset("barrel","shop")

# --- crate
cube("wood_light",(0.7,0.7,0.7),(0,0,0.35))
for r,loc in [((0,0,0),(0,-0.36,0.35)),((0,0,0),(0,0.36,0.35))]:
    cube("wood_dark",(0.72,0.04,0.10),loc)
cube("wood_dark",(0.04,0.72,0.10),(-0.36,0,0.35))
cube("wood_dark",(0.04,0.72,0.10),( 0.36,0,0.35))
cube("wood_dark",(0.74,0.74,0.05),(0,0,0.71))
asset("crate","shop")

# --- sack
ico("leather",0.32,(0,0,0.28),sub=2,scale=(1.0,1.0,0.85))
frustum("leather",0.10,0.06,0.14,(0,0,0.60))                    # tied neck
asset("sack","shop")

# --- potions (red / blue / green)
for color,name in [("glass_red","potion_red"),("glass_blue","potion_blue"),("glass_green","potion_green")]:
    sph(color,0.14,(0,0,0.15))
    cyl(color,0.05,0.12,(0,0,0.31),v=6)
    cyl("wood_dark",0.055,0.05,(0,0,0.39),v=6)                  # cork
    asset(name,"shop")

# --- shop_sign (standalone post sign)
cyl("wood_dark",0.07,1.9,(0,0,0.95),v=6)
cube("wood_dark",(0.9,0.08,0.08),(0.35,0,1.75))
cube("wood_light",(0.62,0.06,0.44),(0.55,0,1.45))
sph("glass_red",0.10,(0.55,-0.04,1.45))
asset("shop_sign","shop")

# --- coin_pile
cyl("gold",0.30,0.08,(0,0,0.04),v=9)
cyl("gold",0.20,0.08,(0.05,0.04,0.12),v=9)
cyl("gold",0.11,0.08,(-0.03,-0.02,0.20),v=9)
cyl("gold",0.05,0.03,(0.14,-0.10,0.10),v=8)
cyl("gold",0.05,0.03,(-0.16,0.12,0.10),v=8)
asset("coin_pile","shop")

# --- rug
cube("cloth_red",(1.6,1.0,0.03),(0,0,0.015))
cube("gold",(1.7,1.1,0.02),(0,0,0.005))
asset("rug","shop")
report()
