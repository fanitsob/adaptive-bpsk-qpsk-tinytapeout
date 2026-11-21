import sys, numpy as np
h=np.array([-2,-1,2,5,5,-2,-11,-16,-7,17,50,79,91,79,50,17,-7,-16,-11,-2,5,5,2,-1,-2])
qpsk=int(sys.argv[1]); K=int(sys.argv[2])
bursts={}; cur=None; ovf=None
for l in sys.stdin:
    t=l.split()
    if not t: continue
    if t[0]=="BURST": cur=int(t[1]); bursts[cur]={"sym":[],"S":[]}
    elif t[0]=="SYM": bursts[cur]["sym"].append((1 if int(t[1]) else -1,(1 if int(t[2]) else -1) if qpsk else 0))
    elif t[0]=="S": bursts[cur]["S"].append((int(t[1]),int(t[2])))
    elif t[0]=="OVF": ovf=int(t[1])
ok=True
for b in (0,1,2):
    sy=bursts[b]["sym"]; n=len(sy)
    slots=(n-1)*K+1+6
    xi=np.zeros(slots*4+30); xq=np.zeros(slots*4+30)
    for j,(i,q) in enumerate(sy): xi[j*K*4]=i; xq[j*K*4]=q
    ri=np.convolve(xi,h)[:slots*4]; rq=np.convolve(xq,h)[:slots*4]
    oi=[v for c,v in bursts[b]["S"] if c==0]; oq=[v for c,v in bursts[b]["S"] if c==1]
    good = (oi==[int(v) for v in ri]) and (oq==[int(v) for v in rq])
    print(f"burst {b}: expected {slots*4} samples/channel, got I={len(oi)} Q={len(oq)}  match={good}")
    ok&=good
print("overflow flag:",ovf,"  ALL MATCH" if ok else "  MISMATCH")
sys.exit(0 if (ok and ovf == 0) else 1)
