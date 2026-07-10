from lowpoly import *

# --- cave_entrance: rocky arch with dark opening
rock("stone_dark",1.1,(-1.5,0,0.9),seed=21,scale=(1.0,1.2,1.5))
rock("stone_dark",1.1,( 1.5,0,0.9),seed=22,scale=(1.0,1.2,1.5))
rock("stone",1.3,(0,0.2,2.4),seed=23,scale=(1.6,1.1,0.8))       # top slab
rock("stone",0.5,(-0.9,-0.6,0.35),seed=24)
rock("stone",0.45,( 1.0,-0.55,0.3),seed=25)
cube("dark",(1.7,0.3,1.9),(0,0.45,0.95))                        # dark opening
asset("cave_entrance","cave")

# --- rocks
rock("stone",0.28,(0,0,0.20),seed=31); asset("rock_small","cave")
rock("stone",0.55,(0,0,0.40),seed=32,scale=(1.2,1.0,0.85)); asset("rock_medium","cave")
rock("stone_dark",1.0,(0,0,0.72),seed=33,scale=(1.3,1.1,0.9))
rock("stone",0.45,(0.9,0.4,0.3),seed=34)
asset("rock_large","cave")

# --- stalagmite / stalactite
cone("stone",0.30,0.9,(0,0,0.45),v=7)
cone("stone_dark",0.18,0.55,(0.25,0.15,0.27),v=6)
asset("stalagmite","cave")
cone("stone",0.30,0.9,(0,0,-0.45),rot=(np.pi,0,0),v=7)
cone("stone_dark",0.16,0.5,(-0.22,0.12,-0.25),rot=(np.pi,0,0),v=6)
asset("stalactite","cave")   # hang from ceiling: origin at top

# --- crystal clusters
for cm,name in [("crystal_purple","crystal_cluster_purple"),("crystal_blue","crystal_cluster_blue")]:
    cone(cm,0.14,0.75,(0,0,0.37),rot=(0.1,0.15,0),v=5)
    cone(cm,0.10,0.5,(0.22,0.10,0.25),rot=(0.2,-0.5,0),v=5)
    cone(cm,0.09,0.42,(-0.20,0.05,0.21),rot=(-0.15,0.45,0),v=5)
    cone(cm,0.07,0.30,(0.05,-0.22,0.15),rot=(-0.4,0.1,0),v=5)
    rock("stone_dark",0.30,(0,0,0.08),seed=41)
    asset(name,"cave")

# --- bone_pile
cube("bone",(0.26,0.24,0.24),(0.15,0.1,0.14))                   # skull
cube("dark",(0.06,0.03,0.06),(0.10,0.22,0.16))
cube("dark",(0.06,0.03,0.06),(0.22,0.22,0.16))
cyl("bone",0.035,0.5,(-0.15,-0.05,0.05),rot=(0,np.pi/2,0.4),v=5)
cyl("bone",0.03,0.4,(-0.05,0.18,0.04),rot=(0,np.pi/2,-0.7),v=5)
cyl("bone",0.03,0.35,(0.0,-0.2,0.04),rot=(0,np.pi/2,1.2),v=5)
asset("bone_pile","cave")

# --- torch_wall (mount against wall at -Y)
cube("iron",(0.10,0.06,0.24),(0,-0.03,0.0))
cyl("wood_dark",0.035,0.40,(0,0.06,0.10),rot=(0.5,0,0))
cone("flame",0.09,0.22,(0,0.16,0.38),v=6)
cone("flame",0.05,0.12,(0,0.16,0.50),v=5)
asset("torch_wall","cave")

# --- cave_wall: chunky rock wall segment (2m wide)
rock("stone_dark",0.9,(-0.7,0,0.8),seed=51,scale=(0.9,0.6,1.4))
rock("stone_dark",0.9,( 0.7,0,0.9),seed=52,scale=(0.9,0.6,1.5))
rock("stone",0.7,(0,0,1.6),seed=53,scale=(1.2,0.55,0.9))
rock("stone",0.5,(0,-0.1,0.4),seed=54,scale=(1.3,0.6,0.7))
asset("cave_wall","cave")

# --- cave_floor: rough ground tile 4x4
c=cube("stone_dark",(4.0,4.0,0.3),(0,0,0.15))
rock("stone",0.3,(-1.2,0.8,0.28),seed=55,scale=(1,1,0.4))
rock("stone",0.25,(1.3,-1.0,0.26),seed=56,scale=(1,1,0.4))
asset("cave_floor","cave")
report()
