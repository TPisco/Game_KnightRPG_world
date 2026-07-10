from lowpoly import *
# All weapons: grip at origin area, blade/barrel up +Z (guns forward +Y).

def hilt(guard_m="iron", grip_m="leather", pommel_m="gold", gw=0.20):
    cyl(grip_m,0.028,0.18,(0,0,0.07))
    sph(pommel_m,0.045,(0,0,-0.04))
    cube(guard_m,(gw,0.055,0.055),(0,0,0.175))

# --- sword_basic: simple soldier blade
hilt()
cube("steel",(0.075,0.022,0.52),(0,0,0.46))
cone("steel",0.052,0.09,(0,0,0.75),v=4)
asset("sword_basic","weapons")

# --- sword_knight: longer, gold guard, blue gem
hilt(guard_m="gold",pommel_m="gold",gw=0.24)
sph("glass_blue",0.035,(0,0.04,0.175))
cube("steel",(0.085,0.024,0.68),(0,0,0.545))
cube("steel_dark",(0.03,0.026,0.60),(0,0,0.50))            # fuller
cone("steel",0.058,0.10,(0,0,0.93),v=4)
asset("sword_knight","weapons")

# --- sword_fractured: jagged purple crystal blade (signature item)
hilt(guard_m="steel_dark",pommel_m="crystal_purple")
cube("crystal_purple",(0.08,0.03,0.34),(0,0,0.37),rot=(0,0.10,0))
cube("crystal_purple",(0.07,0.028,0.30),(0.02,0,0.62),rot=(0,-0.14,0))
cube("crystal_purple",(0.05,0.026,0.22),(-0.015,0,0.84),rot=(0,0.08,0))
cone("crystal_purple",0.04,0.10,(0,0,0.98),v=4)
asset("sword_fractured","weapons")

# --- greatsword: two-hand blade
cyl("leather",0.032,0.30,(0,0,0.10))
sph("iron",0.055,(0,0,-0.07))
cube("iron",(0.30,0.06,0.06),(0,0,0.28))
cube("steel",(0.13,0.03,0.85),(0,0,0.72))
cone("steel",0.09,0.14,(0,0,1.21),v=4)
asset("greatsword","weapons")

# --- axe_battle
cyl("wood",0.035,0.85,(0,0,0.35))
cube("iron",(0.045,0.045,0.09),(0,0,0.74))
cube("steel",(0.26,0.035,0.20),(0.14,0,0.70))               # blade slab
cube("steel",(0.10,0.037,0.30),(0.05,0,0.70))               # blade root
cone("iron",0.03,0.08,(0,0,0.82),v=4)                       # top spike
asset("axe_battle","weapons")

# --- dagger
cyl("leather",0.022,0.12,(0,0,0.05))
sph("iron",0.032,(0,0,-0.025))
cube("iron",(0.12,0.04,0.035),(0,0,0.12))
cube("steel",(0.05,0.018,0.22),(0,0,0.24))
cone("steel",0.034,0.06,(0,0,0.38),v=4)
asset("dagger","weapons")

# --- staff_arcane: wooden staff, gold cradle, purple crystal
cyl("wood_dark",0.032,1.40,(0,0,0.70))
frustum("gold",0.07,0.10,0.10,(0,0,1.43))
ico("crystal_purple",0.11,(0,0,1.58),sub=1,scale=(0.8,0.8,1.35))
sph("gold",0.045,(0,0,0.02))
asset("staff_arcane","weapons")

# --- staff_fire: dark staff with flame crystal and iron ring
cyl("wood_dark",0.034,1.30,(0,0,0.65))
ring("iron",0.10,0.075,0.05,(0,0,1.33))
ico("flame",0.10,(0,0,1.46),sub=1,scale=(0.85,0.85,1.4))
cone("flame",0.05,0.14,(0,0,1.62),v=6)
cyl("iron",0.04,0.06,(0,0,0.06),v=8)
asset("staff_fire","weapons")

# --- gun_flintlock: pistol, barrel forward +Y
cube("wood_dark",(0.05,0.10,0.16),(0,-0.02,0.02),rot=(0.5,0,0))   # grip
cube("wood",(0.06,0.22,0.07),(0,0.08,0.115))                      # stock body
cyl("steel_dark",0.028,0.30,(0,0.24,0.14),rot=(np.pi/2,0,0))      # barrel
cyl("steel",0.036,0.05,(0,0.38,0.14),rot=(np.pi/2,0,0))           # muzzle band
cube("iron",(0.03,0.05,0.06),(0,0.05,0.19))                       # hammer
cube("gold",(0.015,0.05,0.03),(0,0.10,0.075))                     # trigger guard
asset("gun_flintlock","weapons")

# --- gun_blunderbuss: flared muzzle rifle
cube("wood",(0.07,0.34,0.09),(0,0.02,0.10))                       # stock
cube("wood_dark",(0.06,0.12,0.14),(0,-0.14,0.04),rot=(0.4,0,0))   # shoulder stock
cyl("steel_dark",0.032,0.34,(0,0.30,0.13),rot=(np.pi/2,0,0))
frustum("steel",0.035,0.075,0.12,(0,0.50,0.13),rot=(-np.pi/2,0,0))
cube("iron",(0.03,0.05,0.06),(0,0.02,0.17))
asset("gun_blunderbuss","weapons")

# --- shield_round: face toward +Y
cyl("wood",0.34,0.05,(0,0,0.34),rot=(np.pi/2,0,0),v=12)
cyl("iron",0.36,0.02,(0,0.01,0.34),rot=(np.pi/2,0,0),v=12)        # rim
sph("steel",0.09,(0,0.05,0.34))                                   # boss
asset("shield_round","weapons")

# --- shield_kite: knight kite shield
cube("steel_dark",(0.42,0.05,0.55),(0,0,0.42),rot=(0,np.pi/4,0))  # diamond body
cube("cloth_blue",(0.26,0.02,0.34),(0,-0.032,0.42),rot=(0,np.pi/4,0))
cube("gold",(0.05,0.02,0.30),(0,-0.045,0.42))                     # heraldic stripe
asset("shield_kite","weapons")
report()
