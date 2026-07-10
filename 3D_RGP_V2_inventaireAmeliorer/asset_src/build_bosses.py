from lowpoly import *

# ================= MINI-BOSSES (~2.2-2.6m) =================

# --- miniboss_cave_guardian: huge red brute with horns (matches in-game red guardian)
cube("red_brute",(0.30,0.40,0.18),(-0.22,0.03,0.09))
cube("red_brute",(0.30,0.40,0.18),( 0.22,0.03,0.09))
cube("red_brute",(0.26,0.26,0.55),(-0.22,0,0.46))
cube("red_brute",(0.26,0.26,0.55),( 0.22,0,0.46))
cube("dark",(0.78,0.46,0.20),(0,0,0.83))                       # belt
cube("red_brute",(0.85,0.55,0.75),(0,0,1.32))                  # massive torso
cube("dark",(0.30,0.34,0.22),(-0.58,0,1.62))                   # shoulder L
cube("dark",(0.30,0.34,0.22),( 0.58,0,1.62))
cube("red_brute",(0.22,0.22,0.62),(-0.58,0,1.20))
cube("red_brute",(0.22,0.22,0.62),( 0.58,0,1.20))
sph("red_brute",0.17,(-0.58,0.04,0.82))                        # big fists
sph("red_brute",0.17,( 0.58,0.04,0.82))
cube("red_brute",(0.42,0.40,0.36),(0,0,1.90))                  # head
cube("crystal_purple",(0.07,0.03,0.06),(-0.10,0.21,1.94))      # glowing eyes
cube("crystal_purple",(0.07,0.03,0.06),( 0.10,0.21,1.94))
cone("bone",0.07,0.30,(-0.24,0,2.12),rot=(0,-0.6,0),v=5)       # horn L
cone("bone",0.07,0.30,( 0.24,0,2.12),rot=(0, 0.6,0),v=5)
cube("crystal_purple",(0.10,0.08,0.16),(-0.20,-0.26,1.48),rot=(0.3,0.2,0))  # back shards
cube("crystal_purple",(0.08,0.07,0.20),( 0.16,-0.28,1.55),rot=(-0.2,-0.3,0))
asset("miniboss_cave_guardian","minibosses")

# --- miniboss_crystal_golem: stone golem with purple crystals
rock("stone_dark",0.34,(-0.26,0,0.30),seed=11)
rock("stone_dark",0.34,( 0.26,0,0.30),seed=12)
rock("stone",0.60,(0,0,1.05),seed=13,scale=(1.1,0.9,1.05))     # torso boulder
rock("stone_dark",0.26,(-0.68,0,1.10),seed=14)
rock("stone_dark",0.26,( 0.68,0,1.10),seed=15)
rock("stone",0.22,(-0.68,0.02,0.60),seed=16)
rock("stone",0.22,( 0.68,0.02,0.60),seed=17)
rock("stone",0.30,(0,0.05,1.80),seed=18,scale=(1,0.95,0.9))    # head
cube("crystal_purple",(0.08,0.03,0.07),(-0.09,0.28,1.84))
cube("crystal_purple",(0.08,0.03,0.07),( 0.09,0.28,1.84))
cube("crystal_purple",(0.14,0.12,0.42),(0,-0.42,1.45),rot=(0.35,0,0))     # back crystal
cube("crystal_purple",(0.10,0.09,0.30),(-0.30,-0.35,1.30),rot=(0.3,0.3,0))
cube("crystal_purple",(0.10,0.09,0.30),( 0.30,-0.35,1.30),rot=(0.3,-0.3,0))
asset("miniboss_crystal_golem","minibosses")

# --- miniboss_orc_warlord: armored orc champion
cube("iron",(0.24,0.32,0.14),(-0.16,0.02,0.07))
cube("iron",(0.24,0.32,0.14),( 0.16,0.02,0.07))
cube("orc",(0.20,0.20,0.50),(-0.16,0,0.42))
cube("orc",(0.20,0.20,0.50),( 0.16,0,0.42))
cube("leather",(0.60,0.38,0.16),(0,0,0.74))
cube("iron",(0.64,0.42,0.60),(0,0,1.14))                       # armored torso
cube("gold",(0.20,0.05,0.20),(0,0.22,1.20))                    # emblem
cube("iron",(0.30,0.36,0.20),(-0.44,0,1.42))
cube("iron",(0.30,0.36,0.20),( 0.44,0,1.42))
cone("bone",0.06,0.18,(-0.44,0,1.60),v=5)                      # pauldron spikes
cone("bone",0.06,0.18,( 0.44,0,1.60),v=5)
cube("orc",(0.18,0.18,0.52),(-0.44,0,1.06))
cube("orc",(0.18,0.18,0.52),( 0.44,0,1.06))
sph("orc",0.13,(-0.44,0.03,0.74))
sph("orc",0.13,( 0.44,0.03,0.74))
cube("orc",(0.38,0.36,0.34),(0,0,1.62))
cube("dark",(0.07,0.03,0.06),(-0.09,0.185,1.66))
cube("dark",(0.07,0.03,0.06),( 0.09,0.185,1.66))
cone("bone",0.05,0.14,(-0.12,0.17,1.50),rot=(np.pi/2,0,0),v=4)
cone("bone",0.05,0.14,( 0.12,0.17,1.50),rot=(np.pi/2,0,0),v=4)
cube("iron",(0.42,0.40,0.14),(0,0,1.84))                       # helm
cone("bone",0.06,0.26,(-0.20,0,1.98),rot=(0,-0.5,0),v=5)
cone("bone",0.06,0.26,( 0.20,0,1.98),rot=(0, 0.5,0),v=5)
asset("miniboss_orc_warlord","minibosses")

# ================= BOSSES (~3.2-3.8m) =================

# --- boss_fractured_guardian: purple crowned giant with floating shards (boss #1)
cube("cloth_purple",(0.40,0.50,0.24),(-0.28,0.03,0.12))
cube("cloth_purple",(0.40,0.50,0.24),( 0.28,0.03,0.12))
cube("cloth_purple",(0.34,0.34,0.80),(-0.28,0,0.68))
cube("cloth_purple",(0.34,0.34,0.80),( 0.28,0,0.68))
cube("void",(1.00,0.60,0.26),(0,0,1.18))
cube("cloth_purple",(1.05,0.65,1.00),(0,0,1.80))               # giant torso
cube("gold",(0.26,0.06,0.26),(0,0.34,1.90))                    # emblem
cube("void",(0.38,0.44,0.28),(-0.72,0,2.20))
cube("void",(0.38,0.44,0.28),( 0.72,0,2.20))
cube("cloth_purple",(0.26,0.26,0.80),(-0.72,0,1.62))
cube("cloth_purple",(0.26,0.26,0.80),( 0.72,0,1.62))
sph("void",0.20,(-0.72,0.05,1.12))
sph("void",0.20,( 0.72,0.05,1.12))
cube("cloth_purple",(0.52,0.48,0.46),(0,0,2.58))               # head
cube("crystal_purple",(0.09,0.03,0.08),(-0.12,0.25,2.62))
cube("crystal_purple",(0.09,0.03,0.08),( 0.12,0.25,2.62))
cube("gold",(0.56,0.52,0.14),(0,0,2.86))                       # crown base
cone("gold",0.07,0.22,(-0.20,0,3.02),v=4)
cone("gold",0.07,0.22,( 0.20,0,3.02),v=4)
cone("gold",0.08,0.28,(0,0,3.06),v=4)
cube("crystal_purple",(0.12,0.10,0.34),(-1.15,0,2.30),rot=(0,0.3,0.2))   # floating shards
cube("crystal_purple",(0.10,0.09,0.28),( 1.15,0,2.10),rot=(0,-0.3,-0.2))
cube("crystal_purple",(0.09,0.08,0.24),( 0,-0.75,2.75),rot=(0.4,0,0))
asset("boss_fractured_guardian","bosses")

# --- boss_rift_herald: robed summoner with staff and floating rift ring (boss #2)
frustum("void",0.85,0.45,1.9,(0,0,0.95),v=10)                  # robe
frustum("cloth_purple",0.50,0.35,0.5,(0,0,2.05),v=10)          # shoulders
cone("void",0.40,0.55,(0,0,2.55),v=8)                          # hood
sph("dark",0.17,(0,0.16,2.32))                                 # hood shadow face
cube("crystal_purple",(0.06,0.03,0.05),(-0.07,0.30,2.36))      # eyes
cube("crystal_purple",(0.06,0.03,0.05),( 0.07,0.30,2.36))
cube("void",(0.20,0.20,0.70),(-0.62,0,1.85),rot=(0,0.25,0))    # arm L
cube("void",(0.20,0.20,0.70),( 0.62,0.15,1.90),rot=(-0.4,-0.25,0))  # arm R raised
cyl("wood_dark",0.045,2.2,(0.85,0.35,1.45))                    # staff
ico("crystal_purple",0.16,(0.85,0.35,2.70),sub=1,scale=(0.8,0.8,1.3))
ring("crystal_purple",0.55,0.45,0.08,(0,-0.9,2.9),rot=(np.pi/2.5,0,0),v=16)  # rift ring
cube("crystal_purple",(0.08,0.07,0.22),(-0.5,-0.85,2.6),rot=(0.3,0.2,0.4))
cube("crystal_purple",(0.07,0.06,0.18),( 0.5,-0.9,3.15),rot=(-0.3,0.1,-0.3))
asset("boss_rift_herald","bosses")

# --- boss_void_warden: colossal dark knight, void orb chest, greatsword (final boss)
cube("steel_dark",(0.42,0.55,0.26),(-0.30,0.03,0.13))
cube("steel_dark",(0.42,0.55,0.26),( 0.30,0.03,0.13))
cube("steel_dark",(0.36,0.36,0.85),(-0.30,0,0.73))
cube("steel_dark",(0.36,0.36,0.85),( 0.30,0,0.73))
cube("void",(1.05,0.62,0.28),(0,0,1.28))
cube("steel_dark",(1.10,0.70,1.05),(0,0,1.95))                 # torso
ico("crystal_purple",0.20,(0,0.36,2.05),sub=1)                 # void orb core
ring("gold",0.28,0.22,0.06,(0,0.37,2.05),rot=(np.pi/2,0,0),v=12)
cube("void",(0.46,0.52,0.34),(-0.78,0,2.42))                   # pauldron L
cube("void",(0.46,0.52,0.34),( 0.78,0,2.42))
cone("steel_dark",0.09,0.30,(-0.90,0,2.62),rot=(0,-0.5,0),v=5)
cone("steel_dark",0.09,0.30,( 0.90,0,2.62),rot=(0, 0.5,0),v=5)
cube("steel_dark",(0.28,0.28,0.85),(-0.78,0,1.75))
cube("steel_dark",(0.28,0.28,0.85),( 0.78,0,1.75))
sph("steel_dark",0.20,(-0.78,0.05,1.22))
sph("steel_dark",0.20,( 0.78,0.05,1.22))
cube("steel_dark",(0.52,0.50,0.48),(0,0,2.80))                 # helm head
cube("crystal_purple",(0.30,0.04,0.10),(0,0.26,2.82))          # glowing visor
cone("steel_dark",0.08,0.34,(-0.26,0,3.06),rot=(0,-0.55,0),v=5)
cone("steel_dark",0.08,0.34,( 0.26,0,3.06),rot=(0, 0.55,0),v=5)
cube("cloth_purple",(0.90,0.06,1.60),(0,-0.42,1.75))           # war cape
# greatsword planted in right hand
cube("dark",(0.30,0.08,0.08),(0.78,0.35,1.02))
cube("steel_dark",(0.16,0.045,1.60),(0.78,0.35,1.85))
cone("steel_dark",0.11,0.22,(0.78,0.35,2.76),v=4)
asset("boss_void_warden","bosses")
report()
