import os, math, io
import numpy as np
import trimesh
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
from PIL import Image, ImageDraw, ImageFont

ROOT="/sessions/stoic-sharp-hawking/mnt/3D_RGP_V2_inventaireAmeliorer/assets/model/FantasyPack"
OUT="/sessions/stoic-sharp-hawking/mnt/outputs/previews"
os.makedirs(OUT,exist_ok=True)
LIGHT=np.array([0.4,0.7,0.6]); LIGHT=LIGHT/np.linalg.norm(LIGHT)

def render_asset(path,px=340):
    scene=trimesh.load(path)
    fig=plt.figure(figsize=(px/100,px/100),dpi=100)
    ax=fig.add_subplot(111,projection="3d")
    allv=[]
    for name,geom in scene.geometry.items():
        tf=scene.graph.get(name)[0] if name in scene.graph.nodes_geometry else np.eye(4)
        g=geom.copy(); g.apply_transform(tf)
        v=g.vertices.copy()
        # glTF Y-up -> plot Z-up for nicer view: (x,y,z)->(x,-z,y)
        v=np.column_stack([v[:,0],-v[:,2],v[:,1]])
        tris=v[g.faces]
        col=[0.7,0.7,0.7]; em=[0,0,0]
        m=getattr(g.visual,"material",None)
        if m is not None:
            if m.baseColorFactor is not None:
                bc=np.array(m.baseColorFactor[:3],dtype=float)
                col=(bc/255.0 if bc.max()>1 else bc)
            if getattr(m,"emissiveFactor",None) is not None:
                em=np.array(m.emissiveFactor[:3],dtype=float)
                if em.max()>1: em=em/255.0
        n=np.cross(tris[:,1]-tris[:,0],tris[:,2]-tris[:,0])
        n=n/(np.linalg.norm(n,axis=1,keepdims=True)+1e-9)
        lam=np.clip(n@LIGHT,0,1)*0.65+0.35
        fc=np.clip(np.outer(lam,col)+np.array(em)*0.9,0,1)
        pc=Poly3DCollection(tris,facecolors=fc,edgecolors="none")
        ax.add_collection3d(pc)
        allv.append(v)
    V=np.vstack(allv)
    c=(V.max(0)+V.min(0))/2; r=(V.max(0)-V.min(0)).max()/2*1.15+1e-6
    ax.set_xlim(c[0]-r,c[0]+r); ax.set_ylim(c[1]-r,c[1]+r); ax.set_zlim(c[2]-r,c[2]+r)
    ax.view_init(elev=18,azim=-50)
    ax.set_axis_off(); ax.set_box_aspect([1,1,1])
    fig.subplots_adjust(left=0,right=1,top=1,bottom=0)
    buf=io.BytesIO(); fig.savefig(buf,format="png",transparent=False,facecolor="#1a1a22")
    plt.close(fig); buf.seek(0)
    return Image.open(buf).convert("RGB")

try: font=ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",15)
except: font=ImageFont.load_default()
try: bigfont=ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",26)
except: bigfont=font

ORDER=["characters","weapons","mobs","minibosses","bosses","shop","cave","dungeon","props"]
sheets=[]
for cat in ORDER:
    folder=os.path.join(ROOT,cat)
    files=sorted(f for f in os.listdir(folder) if f.endswith(".glb"))
    tiles=[]
    for f in files:
        img=render_asset(os.path.join(folder,f))
        d=ImageDraw.Draw(img)
        d.rectangle([0,img.height-24,img.width,img.height],fill="#000000")
        d.text((8,img.height-21),f[:-4],fill="#e8e0c8",font=font)
        tiles.append(img)
    cols=min(6,len(tiles)); rows=math.ceil(len(tiles)/cols)
    W,H=tiles[0].size
    sheet=Image.new("RGB",(cols*W,rows*H+44),"#101018")
    d=ImageDraw.Draw(sheet)
    d.text((14,8),f"KnightRPG FantasyPack — {cat} ({len(tiles)})",fill="#f0d080",font=bigfont)
    for i,t in enumerate(tiles):
        sheet.paste(t,((i%cols)*W,44+(i//cols)*H))
    p=os.path.join(OUT,f"pack_{cat}.png"); sheet.save(p); sheets.append(sheet)
    print("sheet:",p,sheet.size)

# overview: stack all sheets scaled to same width
TW=1600
scaled=[s.resize((TW,int(s.height*TW/s.width))) for s in sheets]
total=Image.new("RGB",(TW,sum(s.height for s in scaled)),"#101018")
y=0
for s in scaled:
    total.paste(s,(0,y)); y+=s.height
total.save(os.path.join(OUT,"pack_overview.png"))
print("overview:",os.path.join(OUT,"pack_overview.png"),total.size)
