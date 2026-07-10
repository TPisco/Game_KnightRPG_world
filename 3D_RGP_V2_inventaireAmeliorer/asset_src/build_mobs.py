from lowpoly import *
# Enemies face +Y. Heights: basic ~1.0-1.3m, medium ~1.6m.

# --- mob_goblin (basic): small, big ears, loincloth
cube("goblin",(0.14,0.18,0.10),(-0.10,0.02,0.05))
cube("goblin",(0.14,0.18,0.10),( 0.10,0.02,0.05))
cube("goblin",(0.12,0.12,0.25),(-0.10,0,0.22))
cube("goblin",(0.12,0.12,0.25),( 0.10,0,0.22))
cube("leather",(0.34,0.20,0.12),(0,0,0.40))                  # loincloth
cube("goblin",(0.36,0.26,0.34),(0,0,0.62))                   # body
cube("goblin",(0.11,0.11,0.32),(-0.26,0,0.62))
cube("goblin",(0.11,0.11,0.32),( 0.26,0,0.62))
sph("goblin",0.075,(-0.26,0.02,0.44))
sph("goblin",0.075,( 0.26,0.02,0.44))
cube("goblin",(0.30,0.28,0.28),(0,0,0.96))                   # head
cone("goblin",0.07,0.22,(-0.22,0,1.02),rot=(0,-np.pi/2,0),v=4)  # ear L
cone("goblin",0.07,0.22,( 0.22,0,1.02),rot=(0, np.pi/2,0),v=4)  # ear R
cube("dark",(0.05,0.03,0.05),(-0.08,0.145,0.99))             # eye
cube("dark",(0.05,0.03,0.05),( 0.08,0.145,0.99))
cone("goblin",0.05,0.10,(0,0.17,0.92),rot=(np.pi/2,0,0),v=4) # nose
asset("mob_goblin","mobs")

# --- mob_goblin_brute (medium): bigger goblin, iron pauldron, club fist
cube("goblin",(0.20,0.26,0.13),(-0.14,0.02,0.065))
cube("goblin",(0.20,0.26,0.13),( 0.14,0.02,0.065))
cube("goblin",(0.16,0.16,0.34),(-0.14,0,0.30))
cube("goblin",(0.16,0.16,0.34),( 0.14,0,0.30))
cube("leather",(0.48,0.30,0.14),(0,0,0.54))
cube("goblin",(0.52,0.38,0.48),(0,0,0.86))
cube("iron",(0.26,0.30,0.18),(-0.36,0,1.10))                 # pauldron
cube("goblin",(0.15,0.15,0.44),(-0.36,0,0.80))
cube("goblin",(0.15,0.15,0.44),( 0.36,0,0.80))
sph("goblin",0.11,(-0.36,0.03,0.54))
sph("goblin",0.11,( 0.36,0.03,0.54))
cube("goblin",(0.36,0.34,0.32),(0,0,1.28))
cone("goblin",0.08,0.26,(-0.26,0,1.34),rot=(0,-np.pi/2,0),v=4)
cone("goblin",0.08,0.26,( 0.26,0,1.34),rot=(0, np.pi/2,0),v=4)
cube("dark",(0.06,0.03,0.05),(-0.09,0.175,1.32))
cube("dark",(0.06,0.03,0.05),( 0.09,0.175,1.32))
cone("bone",0.04,0.10,(-0.10,0.16,1.18),rot=(np.pi/2,0,0),v=4)  # tusk
cone("bone",0.04,0.10,( 0.10,0.16,1.18),rot=(np.pi/2,0,0),v=4)
asset("mob_goblin_brute","mobs")

# --- mob_skeleton (basic)
cube("bone",(0.13,0.20,0.08),(-0.10,0.02,0.04))
cube("bone",(0.13,0.20,0.08),( 0.10,0.02,0.04))
cyl("bone",0.045,0.42,(-0.10,0,0.29),v=6)
cyl("bone",0.045,0.42,( 0.10,0,0.29),v=6)
cube("bone",(0.34,0.20,0.10),(0,0,0.55))                     # pelvis
cyl("bone",0.04,0.30,(0,0,0.78),v=6)                         # spine
cube("bone",(0.40,0.24,0.08),(0,0,0.72))                     # rib 1
cube("bone",(0.44,0.26,0.08),(0,0,0.86))                     # rib 2
cube("bone",(0.40,0.24,0.08),(0,0,1.00))                     # rib 3
cyl("bone",0.04,0.40,(-0.28,0,0.82),v=6)
cyl("bone",0.04,0.40,( 0.28,0,0.82),v=6)
cube("bone",(0.26,0.24,0.26),(0,0,1.24))                     # skull
cube("bone",(0.18,0.20,0.10),(0,0.02,1.06))                  # jaw
cube("dark",(0.06,0.03,0.07),(-0.07,0.125,1.26))
cube("dark",(0.06,0.03,0.07),( 0.07,0.125,1.26))
asset("mob_skeleton","mobs")

# --- mob_skeleton_armored (medium): + helmet, pauldrons, chest plate
cube("bone",(0.13,0.20,0.08),(-0.10,0.02,0.04))
cube("bone",(0.13,0.20,0.08),( 0.10,0.02,0.04))
cyl("bone",0.045,0.42,(-0.10,0,0.29),v=6)
cyl("bone",0.045,0.42,( 0.10,0,0.29),v=6)
cube("bone",(0.34,0.20,0.10),(0,0,0.55))
cube("iron",(0.44,0.28,0.40),(0,0,0.84))                     # chest plate
cube("iron",(0.20,0.24,0.14),(-0.32,0,1.04))
cube("iron",(0.20,0.24,0.14),( 0.32,0,1.04))
cyl("bone",0.04,0.40,(-0.32,0,0.78),v=6)
cyl("bone",0.04,0.40,( 0.32,0,0.78),v=6)
cube("bone",(0.26,0.24,0.26),(0,0,1.24))
cube("iron",(0.30,0.28,0.16),(0,0,1.40))                     # helmet
cube("iron",(0.06,0.06,0.22),(0,0.12,1.30))                  # nose guard
cube("dark",(0.06,0.03,0.07),(-0.07,0.125,1.26))
cube("dark",(0.06,0.03,0.07),( 0.07,0.125,1.26))
asset("mob_skeleton_armored","mobs")

# --- mob_slime (basic)
ico("slime",0.42,(0,0,0.34),sub=2,scale=(1.0,1.0,0.78))
ico("slime",0.20,(0.18,0.14,0.62),sub=1)                     # blob bump
cube("dark",(0.07,0.03,0.10),(-0.13,0.36,0.42))
cube("dark",(0.07,0.03,0.10),( 0.13,0.36,0.42))
asset("mob_slime","mobs")

# --- mob_mushroom (basic): angry little fungus
frustum("parchment",0.16,0.12,0.35,(0,0,0.28))               # stem
cone("mushroom",0.42,0.30,(0,0,0.62),v=10)                   # cap
sph("parchment",0.05,(-0.18,0.22,0.62))                      # spot
sph("parchment",0.05,( 0.14,-0.26,0.68))
sph("parchment",0.04,( 0.24,0.10,0.60))
cube("dark",(0.05,0.03,0.08),(-0.08,0.145,0.38))
cube("dark",(0.05,0.03,0.08),( 0.08,0.145,0.38))
asset("mob_mushroom","mobs")

# --- mob_void_wisp (basic, floating)
ico("void",0.28,(0,0,0.85),sub=2)
ico("crystal_purple",0.10,(0,0.16,0.85),sub=1)               # glowing eye core
cone("void",0.10,0.30,(0,0,0.52),rot=(np.pi,0,0),v=6)        # wispy tail
ico("crystal_purple",0.05,(-0.30,0,1.02),sub=0)
ico("crystal_purple",0.05,( 0.30,0,0.95),sub=0)
ico("crystal_purple",0.04,( 0.0,-0.28,1.10),sub=0)
asset("mob_void_wisp","mobs")

# --- mob_orc (medium ~1.7m)
cube("leather",(0.20,0.28,0.12),(-0.14,0.02,0.06))
cube("leather",(0.20,0.28,0.12),( 0.14,0.02,0.06))
cube("orc",(0.17,0.17,0.42),(-0.14,0,0.35))
cube("orc",(0.17,0.17,0.42),( 0.14,0,0.35))
cube("leather",(0.50,0.32,0.14),(0,0,0.62))
cube("orc",(0.54,0.36,0.50),(0,0,0.95))
cube("leather",(0.56,0.10,0.52),(0,-0.14,0.95),rot=(0,0,0.5)) # harness strap
cube("orc",(0.16,0.16,0.46),(-0.37,0,0.88))
cube("orc",(0.16,0.16,0.46),( 0.37,0,0.88))
sph("orc",0.11,(-0.37,0.03,0.60))
sph("orc",0.11,( 0.37,0.03,0.60))
cube("orc",(0.34,0.32,0.30),(0,0,1.36))
cube("dark",(0.06,0.03,0.05),(-0.08,0.165,1.40))
cube("dark",(0.06,0.03,0.05),( 0.08,0.165,1.40))
cone("bone",0.045,0.12,(-0.11,0.15,1.26),rot=(np.pi/2,0,0),v=4)
cone("bone",0.045,0.12,( 0.11,0.15,1.26),rot=(np.pi/2,0,0),v=4)
cube("iron",(0.38,0.36,0.10),(0,0,1.54))                     # iron skullcap
asset("mob_orc","mobs")
report()
